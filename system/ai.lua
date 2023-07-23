--[[
local patrol_task =
select {
    condition {deactivate_ground, id},
    sequence {
        condition {is_sensor_in_contact, id},
        action {set_move_intent, id, 0}
        action {flip, id}
    }
    action {set_move_intent_to_flip, id}
}

select {
    invert(
        condition(motion.is_on_ground, id)
    ),
    sequence {
        is_sensor_in_contact(id, spatial(400, 10)),
        action(set_move_intent, id, 0),
        action(flip, id)
    },
    action(move_intent_from_flip, id)
}

local attack_task = 
sequence {
    action(spot_player, id),
    action(move_to_player, id),
    action(charge, id)
    wait(1.0),
    action {set_move_intent, id}
    action {punch, wait}
}

local status = ai(id)

]]--

local assembly = {}

local function run_node(node, ...)
    local type = node.type or "unknown"
    local ass = assembly[type]
    if not ass then return "failure" end
    return ass(node, ...)
end

local function run_sequence(nodes, node_status, ...)
    for index, node in ipairs(nodes) do
        local status = node_status[index] or "pending"
        if status == "pending" then node_status[index] = run_node(node, ...) end
        if node_status[index] ~= "success" then return node_status[index] end
    end

    return "success"
end

function assembly.sequence(root, ...)
    local status = run_sequence(
        root.nodes,
        stack.ensure(nw.component.node_status, root),
        ...
    )

    if status ~= "pending" then stack.remove(nw.component.node_status, root) end

    return status
end

local function run_select(nodes, node_status, ...)
    for index, node in ipairs(nodes) do
        local status = node_status[index] or "pending"
        if status == "pending" then node_status[index] = run_node(node, ...) end
        if node_status[index] ~= "failure" then return node_status[index] end
    end

    return "failure"
end

function assembly.select(root, ...)
    local status = run_select(
        root.nodes,
        stack.ensure(nw.component.node_status, root),
        ...
    )

    if status ~= "pending" then stack.remove(nw.component.node_status, root) end

    return status
end

function assembly.condition(node, ...)
    if not node.condition then return "failure" end
    return node.condition(unpack(node.args)) and "success" or "failure"
end

function assembly.action(node, ...)
    if node.action then node.action(unpack(node.args)) end
    return "success"
end

local ai = {}

function ai.sequence(args)
    return {
        type = "sequence",
        nodes = list(unpack(args))
    }
end

function ai.select(args)
    return {
        type = "select",
        nodes = list(unpack(args))
    }
end

function ai.condition(condition, ...)
    return {
        type = "condition",
        condition = condition,
        args = list(...)
    }
end

function ai.action(action, ...)
    return {
        type = "action",
        action = action,
        args = list(...)
    }
end

function assembly.invert(node, ...)
    local status = run_node(node.child, ...)
    if status == "pending" then
        return "pending"
    elseif status == "failure" then
        return "success"
    else
        return "failure"
    end
end

function ai.invert(child)
    return {
        type = "invert",
        child = child
    }
end

-- ASSEMBLY EXTENSIONS

function assembly.wait(node)
    local t = stack.ensure(nw.component.time, node, clock.get())
    if clock.get() - t < node.duration then return "pending" end
    stack.remove(nw.component.time, node)
    return "success"
end

function ai.wait(duration)
    return {
        type = "wait",
        duration = duration
    }
end

function assembly.is_sensor_in_contact(node)
    local r = collision.query_local(node.id, node.sensor, node.filter)
    return List.empty(r) and "failure" or "success"
end

function ai.is_sensor_in_contact(id, sensor, filter)
    return {
        type = "is_sensor_in_contact",
        id = id,
        sensor = sensor,
        filter = filter
    }
end

function assembly.wait_until(node)
    local status = run_node(node.child)
    return status == "success" and "success" or "pending"
end

function ai.wait_until(child)
    return {
        type = "wait_until",
        child = child
    }
end

function ai.enter_puppet_state(id, intent_comp, ...)
    return ai.sequence {
        ai.action(stack.set, intent_comp, id),
        ai.wait_until(
            ai.condition(puppet_animator.is_in_state, id, ...)
        )
    }
end

function ai.exit_puppet_state(id, ...)
    return ai.wait_until(
        ai.invert(
            ai.condition(puppet_animator.is_in_state, id, ...)
        )
    )
end

function assembly.spot_target(node)
    local target = List.head(collision.query_local(node.id, node.sensor, node.filter))
    if not target then return "failure" end

    event.emit("spot_target", node.id, target)

    stack.set(nw.component.target, node.id, target)
    return "success"
end

function ai.spot_target(id, sensor, filter)
    return {
        type = "spot_target",
        id = id,
        sensor = sensor,
        filter = filter or function() return false end
    }
end

function assembly.go_to_target(node)
    local target = stack.get(nw.component.target, node.id):unpack()
    if not target then return "failure" end

    local pos = stack.get(nw.component.position, node.id) or vec2()
    local pos_target = stack.get(nw.component.position, target) or vec2()
    local d = pos_target - pos

    local min = node.min_distance
    local max = node.max_distance

    if min <= math.abs(d.x) and math.abs(d.x) < max  then
        return "success"
    end

    local s = node.speed
    local m = math.abs(d.x) < min and -1 or 1

    stack.set(nw.component.move_intent, node.id, d.x < 0 and -m * s or m * s)
    return "pending"
end

local function go_to_target_distance(distance)
    if type(distance) == "number" then
        return 0, distance
    end
    if type(distance) == "table" then
        local min, max = distance:unpack()
        if not min or not max then error("Invalid distances", min, max) end
        return min, max
    end

    errorf("Unknown distance type %s", type(distance))
end

function ai.go_to_target(id, distance, speed)
    local min, max = go_to_target_distance(distance)
    return {
        type = "go_to_target",
        id = id,
        min_distance = min,
        max_distance = max,
        speed = speed or 1
    }
end

function assembly.fail(node)
    local status = run_node(node.child)
    return status == "pending" and "pending" or "failure"
end

function ai.fail(child)
    return {
        type = "fail",
        child = child
    }
end

function assembly.node(node)
    return node.func(unpack(node.args))
end

function ai.node(func, ...)
    return {
        type = "node",
        args = {...},
        func = func
    }
end

function ai.set(...)
    return ai.action(stack.set, ...)
end

function ai.wait_until_puppet_done(id)
    return ai.wait_until(
        ai.condition(function() return puppet_animator.is_done(id) end)
    )
end

function assembly.rng(node)
    local rng = love.math.random
    return rng() <= node.chance and "success" or "failure"
end

function ai.rng(chance)
    return {
        type = "rng",
        chance = chance
    }
end

function assembly.random_choice(node)
    node.choice = node.choice or choice(node.nodes, node.weights)
    local status = run_node(node.choice)
    if status ~= "pending" then node.choice = nil end
    return status
end

function ai.random_choice(nodes, weights)
    if weights and #nodes ~= #weights then
        error("Node and weights did not match")
    end
    return {
        type = "random_choice",
        nodes = nodes,
        weights = weights,
    }
end

local function weighted_shuffle(nodes, dices)
    local dices = dices or {}
    local roll = list()

    for index, _ in ipairs(nodes) do
        local dice = dices[index] or 100
        roll[index] = dice > 0 and love.math.random(1, dice) or 0
    end

    
    local sorted_roll = roll:argsort()
    
    local sorted_nodes = list()
    
    for i, j in ipairs(sorted_roll) do
        sorted_nodes[#nodes - i + 1] = nodes[j]
    end

    return sorted_nodes
end

function assembly.shuffle_select(node)
    node.select = node.select or ai.select(weighted_shuffle(node.nodes, node.dices))
    local status = run_node(node.select)
    if status ~= "pending" then node.select = nil end
    return status
end

function ai.shuffle_select(nodes, dices)
    return {
        type = "shuffle_select",
        nodes = nodes,
        dices = dices
    }
end

local function test_distance(id, target, min, max)
    local p_i = stack.get(nw.component.position, id)
    local p_j = stack.get(nw.component.position, target)
    if not p_i or not p_j then
        return 
    end
    local dx = p_i.x - p_j.x
    local dy = p_i.y - p_j.y
    local d2 = dx * dx + dy * dy
    local min2 = min * min
    local max2 = max * max
    return min2 <= d2 and d2 < max2
end

local function test_distance_to_target(id, min, max)
    local target = stack.get(nw.component.target, id):head()
    if not target then return end
    return test_distance(id, target, min, max)
end

function ai.test_distance_to_target(id, min, max)
    return ai.condition(test_distance_to_target, id, min, max)
end 

function assembly.turn_towards_target(node)
    local id = node.id
    local target = stack.get(nw.component.target, id):head()
    if not target then return "failure" end

    for _, dt in event.view("update") do
        local p_i = stack.get(nw.component.position, id)
        local p_t = stack.get(nw.component.position, target)
        if not p_i or not p_t then return "failure" end
        local mirror = p_i.x > p_t.x
        if node.invert then mirror = not mirror end
        collision.flip_to(id, mirror)
        return "success"
    end

    return "pending"
end

function ai.turn_towards_target(id, invert)
    return {
        type = "turn_towards_target",
        id = id,
        invert = invert
    }
end

function ai.cooldown(duration)
    local token = {}
    return ai.condition(function()
        local t = stack.get(nw.component.time, token)
        local c = clock.get()
        if not t or duration <= c - t then
            stack.set(nw.component.time, token, c)
            return true
        else
            return false
        end
    end)
end

function ai.hitbox_range(id, state, slice)
    local m = stack.get(nw.component.puppet_state_map, id)
    if not m then
        error("No state map for id", id)
    end
    local v = m[state]
    if not v then errorf("No state '%s' for id %s", state, tostring(id)) end

    for _, f in ipairs(v.frames) do
        --local s = f.slices[slice]
        local s = f:get_slice(slice)
        if s then return vec2(s.x, s.x + s.w) end
    end

    errorf("Unable to find slice %s", slice)
end

ai.run = run_node

return ai