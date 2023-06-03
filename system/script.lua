local patrol_box = {}

function patrol_box.move_to(_, id, goal)
    for _, dt in event.view("update") do
        local pos = stack.ensure(nw.component.position, id)
        local dir = goal - pos
        local l = dir:length()
        local speed = 50
        local step = speed * dt

        if l <= step then
            collision.move_to(id, goal.x, goal.y)
            return "success"
        else
            collision.move(id, step * dir.x / l, step * dir.y / l)
        end
    end

    return "pending"
end

function patrol_box.spin_once(id, args)
    local task = {
        ai.sequence_forget,
            {patrol_box.move_to, id, vec2(-100, -100)},
            {patrol_box.move_to, id, vec2(0, -100)}
    }

    ai.run(args, task)
end

function patrol_box.spin()
    for id, args in stack.view_table(nw.component.script("patrolbox")) do
        patrol_box.spin_once(id, args)
    end
end

local edge_patrol = {}

function edge_patrol.set_move_intent(_, id, v)
    stack.set(nw.component.move_intent, id, v)
    return "success"
end

function edge_patrol.hit_edge(id)
    for _, x, y, cols in event.view("move") do
        for _, colinfo in ipairs(cols) do
            if colinfo.item == id and colinfo.normal.x ~= 0 and colinfo.type == "slide" then
                return true
            end
        end
    end

    return false
end

function edge_patrol.is_sensor_in_contact(_, id)
    local no_ground = #collision.query_local(id, spatial(10, 0, 1, 1)) == 0
    local edge = edge_patrol.hit_edge(id)
    return (edge or no_ground) and "success" or "failure"
end

function edge_patrol.flip(_, id)
    for _, dt in event.view("update") do
        collision.flip(id)
        return "success"
    end

    return "pending"
end

function edge_patrol.deactivate_ground(_, id)
    return motion.is_on_ground(id) and "failure" or "success"
end

--[[
local attack_task = {
    ai.sequence,
        {edge_patrol.acquire_target, id},
        {edge_patrol.rng_roll, id}
        {ai.select,
            {ai.sequence,
                {ai.condition, rng_check, id, 0.1},
                normal_attack(id)
            },
            {ai.sequence,
                {ai.condition, rng_check, id, 0.3},
                ranged_attack(id)
            },
            retreat(id)
        },
}
]]--

function edge_patrol.patrol_task(id)
    return {
        ai.stateless_select,
            {edge_patrol.deactivate_ground, id},
            {ai.sequence_forget,
                {edge_patrol.is_sensor_in_contact, id},
                {edge_patrol.set_move_intent, id, 0},
                {edge_patrol.flip, id}
            },
            {edge_patrol.set_move_intent, id, stack.get(nw.component.mirror, id) and -1 or 1}
    }
end

local function player_controlled_filter(item)
    return stack.get(nw.component.player_controlled, item)
end

function edge_patrol.spot_player(_, id)
    local query = collision.query_local(id, spatial():expand(400, 10), player_controlled_filter)
    local player_id = unpack(query)
    if not player_id then return "failure" end
    stack.set(nw.component.target, id, player_id)
    return "success"
end

function edge_patrol.move_to_player(_, id)
    local target = stack.ensure(nw.component.target, id):unpack()
    if not target then return "failure" end

    local pos = stack.ensure(nw.component.position, id)
    local pos_target = stack.ensure(nw.component.position, target)
    local dx = pos_target.x - pos.x
    
    stack.set(nw.component.move_intent, id, dx > 0 and 1 or -1)
    if math.abs(dx) < 100 then
        return "success"
    end

    if math.abs(dx) > 300 then
        return "failure"
    end


    return "pending"
end

function edge_patrol.set_state(_, id, state, ...)
    stack.set(nw.component.puppet_state, id, state, ...)
    return "success"
end

function edge_patrol.perform_attack(_, id)
    stack.set(nw.component.puppet_state, id, "punch_a")
    return "success"
end

function edge_patrol.wait_for_attack(_, id)
    return puppet_animator.is_done(id) and "success" or "pending"
end

function edge_patrol.wait(data, duration)
    local time = stack.ensure(nw.component.time, data, clock.get())
    return clock.get() - time >= duration and "success" or "pending"
end

function edge_patrol.charge(_, id)
    stack.set(nw.component.punch_intent, id, true)
    return stack.get(nw.component.puppet_state, id).name == "charge" and "success" or "pending"
end

function edge_patrol.punch(_, id)
    local state = stack.get(nw.component.puppet_state, id)  
    if state.name == "charge" then
        stack.set(nw.component.punch_intent, id, false)
        return "pending"
    elseif state.name ~= "fly_punch" then
        return "failure"
    end

    return "success"
end

function edge_patrol.attack_task(id)
    return {
        ai.sequence_forget,
            {edge_patrol.spot_player, id},
            {edge_patrol.move_to_player, id},
            {edge_patrol.charge, id},
            {edge_patrol.wait, 0.4},
            {edge_patrol.set_move_intent, id, 0},
            {edge_patrol.punch, id},
            {edge_patrol.wait, 1.0}
    }
end

function edge_patrol.spin_once(id, args)
    edge_patrol.is_sensor_in_contact("fafa", id)
    local task = {
        ai.select_forget,
            edge_patrol.attack_task(id),
            edge_patrol.patrol_task(id)
    }

    ai.run(args, task)
end

function edge_patrol.spin()
    for id, args in stack.view_table(nw.component.script("edge_patrol")) do
        edge_patrol.spin_once(id, args)
    end
end

local player_boxer = {}

function player_boxer.spin_once(id)
    for _, key in event.view("keypressed") do
        if key == "space" then
            stack.set(nw.component.jump_intent, id)
        elseif key == "a" then
            stack.set(nw.component.punch_intent, id, true)
        elseif key == "d" then
            stack.set(nw.component.dash_intent, id)
        elseif key == "s" then
            stack.set(nw.component.attack_intent, id)
        end
    end

    for _, key in event.view("keyreleased") do
        if key == "a" then
            stack.set(nw.component.punch_intent, id, false)
        end
    end 

    for _, dt in event.view("update") do
        stack.set(nw.component.move_intent, id, input.get_direction_x())
    end
end

function player_boxer.spin()
    for id, _ in stack.view_table(nw.component.script("boxer-player")) do
        player_boxer.spin_once(id)
    end 
end

local player = {}

function player.spin_once(id)
    for _, key in event.view("keypressed") do
        if key == "space" then
            stack.set(nw.component.jump_intent, id)
        elseif key == "d" then
            stack.set(nw.component.dash_intent, id)
        elseif key == "a" then
            stack.set(nw.component.attack_intent, id)
        elseif key == "s" then
            stack.set(nw.component.hitstun_intent, id)
        end
    end

    for _, dt in event.view("update") do
        stack.set(nw.component.move_intent, id, input.get_direction_x())
    end
end

function player.spin()
    for id, _ in stack.view_table(nw.component.script("player")) do
        player.spin_once(id)
    end
end

local door = {}

function door.spin_once(id)
    local target = stack.ensure(nw.component.target, id):unpack()
    if not target then return end
    
    local state = stack.get(nw.component.switch_state, target)
    if state then
        stack.set(nw.component.color, id, 0, 1, 0)
    else
        stack.set(nw.component.color, id, 1, 0, 0)
    end

    for _, dt in event.view("update") do
        local x, y, w, h = collision.get_model_hitbox(id)
        local hb = spatial(x, state and -2 * h or -h, w,  h)
        collision.unregister(id)
        collision.register(id, hb)
    end
end

function door.spin()
    for id, _ in stack.view_table(nw.component.script("door")) do
        door.spin_once(id)
    end
end

local script = {}

function script.spin()
    player.spin()
    player_boxer.spin()
    patrol_box.spin()
    edge_patrol.spin()
    door.spin()
end

return script 