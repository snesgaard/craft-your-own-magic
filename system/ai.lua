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

    if math.abs(d.x) <= node.min_distance then return "success" end

    stack.set(nw.component.move_intent, node.id, d.x < 0 and -1 or 1)
    return "pending"
end

function ai.go_to_target(id, min_distance)
    return {
        type = "go_to_target",
        id = id,
        min_distance = min_distance
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

ai.run = run_node

return ai