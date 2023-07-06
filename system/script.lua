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
            {edge_patrol.spot_player, id, name="spot_player"},
            {edge_patrol.move_to_player, id},
            {edge_patrol.charge, id},
            {edge_patrol.wait, 1.0},
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

function player_boxer.pop_intent(comp, id)
    local intent = stack.get(comp, id)
    if not intent or timer.is_done(intent) then return end
    stack.remove(comp, id)
    return true
end

function player_boxer.pop_extra_jump()
    local v = stack.get(nw.component.jump_extra, id)
    if v then stack.remove(nw.component.jump_extra, id) end
    return v
end

function player_boxer.jump(id)
    return 
    ai.sequence {
        ai.select {
            ai.condition(motion.is_on_ground, id),
            ai.condition(stack.get, nw.component.jump_extra, id)
        },
        ai.condition(player_boxer.pop_intent, nw.component.jump_intent, id),
        ai.action(function()
            motion.jump(id, 40)
            if motion.is_on_ground(id) then
                stack.remove(nw.component.on_ground, id)
                stack.set(nw.component.jump_extra, id)
            else
                stack.remove(nw.component.jump_extra, id)
            end
        end)
    }
end

function player_boxer.hit(id)
    return
    ai.sequence {
        ai.condition(player_boxer.pop_intent, nw.component.attack_intent, id),
        ai.action(function()
            stack.map(nw.component.disable_move, id, add, 1)
            stack.map(nw.component.disable_flip, id, add, 1)
            
            stack.map(nw.component.restore_move, id, add, 1)
            stack.map(nw.component.restore_flip, id, add, 1)
        end),   
        ai.action(stack.set, nw.component.puppet_state, id, "hit"),
        ai.wait_until(ai.condition(puppet_animator.is_done, id)),
        ai.action(stack.set, nw.component.puppet_state, id, "idle")
    }
end

local dash_data = {duration = 0.15}

function dash_data.position(id)
    return stack.get(nw.component.position, id) or vec2()
end

function dash_data.position_change(id, distance, is_vertical)
    local distance = distance or 50
    if is_vertical then
        return vec2(0, -distance)
    else
        return vec2((stack.get(nw.component.mirror, id) and -1 or 1) * distance, 0)
    end
end

function player_boxer.dash(id)
    local data_token = nw.ecs.id.weak("dash_data")

    return 
    ai.sequence {
        ai.condition(function()
            local cd = stack.get(nw.component.dash_cooldown, id)
            return not cd or timer.is_done(cd)
        end),
        ai.condition(player_boxer.pop_intent, nw.component.dash_intent, id),
        ai.action(function()
            stack.map(nw.component.disable_move, id, add, 1)
            stack.map(nw.component.disable_flip, id, add, 1)
            stack.map(nw.component.immune("damage"), id, add, 1)
            
            stack.map(nw.component.restore_move, id, add, 1)
            stack.map(nw.component.restore_flip, id, add, 1)
            stack.map(nw.component.restore_immune("damage"), id, add, 1)

            stack.remove(dash_data.position, data_token)
            stack.remove(dash_data.position_change, data_token)

            stack.set(nw.component.puppet_state, id, "dash")
        end),
        ai.node(function()
            stack.remove(nw.component.velocity, id)

            local state = stack.get(nw.component.puppet_state, id)
            local p = stack.ensure(dash_data.position, data_token, id)
            local dp = stack.ensure(dash_data.position_change, data_token, id)
            local t = clock.get() - state.time
        
            for _, dt in event.view("update") do
                local next_p = ease.linear(t, p, dp, dash_data.duration)
                collision.move_to(id, next_p.x, next_p.y)
            end
        
            if t < dash_data.duration then return "pending" end

            stack.set(nw.component.dash_cooldown, id)
            return "success"
        end)
    }
end

function player_boxer.behavior(id)
    return 
    ai.select {
        ai.fail(
            ai.sequence {
                ai.action(motion.restore, id),
                ai.action(combat.restore, id),
                ai.action(puppet_animator.ensure, id, "idle")
            }
        ),
        ai.fail(player_boxer.jump(id)),
        player_boxer.hit(id),
        player_boxer.dash(id)
    }
end

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

    local behavior = stack.ensure(nw.component.behavior, id, player_boxer.behavior(id))
    ai.run(behavior)
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

local bonk_bot = {}

local function is_terrain(id)
    return stack.get(nw.component.is_terrain, id)
end

local function is_player(id)
    return stack.get(nw.component.player_controlled, id)

end

function bonk_bot.patrol(id)
    return
    ai.select {
        ai.invert(
            ai.condition(motion.is_on_ground, id)
        ),
        ai.sequence {
            ai.select {
                ai.is_sensor_in_contact(id, spatial(10, -10, 1, 1), is_terrain),
                ai.invert(
                    ai.is_sensor_in_contact(id, spatial(10, 0, 1, 1), is_terrain)
                ),
            },
            ai.action(stack.set, nw.component.move_intent, id, 0),
            ai.wait(1),
            ai.action(function()
                for _, _ in event.view("update") do
                    collision.flip_to(id, not stack.get(nw.component.mirror, id))
                    return "success"
                end

                return "pending"
            end),
        },
        ai.action(motion.move_intent_from_flip, id)
    }
end

function bonk_bot.attack(id)
    return
    ai.sequence {
        ai.action(stack.set, nw.component.move_intent, id, 0),
        ai.wait(0.5),
        ai.action(stack.set, nw.component.puppet_state, id, "hit"),
        ai.wait_until(
            ai.condition(function() return puppet_animator.is_done(id) end)
        ),
        ai.action(stack.set, nw.component.puppet_state, id, "idle")
    }
end

function bonk_bot.behavior(id)
    return
    ai.select {
        ai.fail(
            ai.action(puppet_animator.ensure, id, "idle")
        ),
        ai.sequence {
            --ai.is_sensor_in_contact(id, spatial(10, -10, 20, 1), is_player),
            ai.spot_target(id, spatial(0, 0, 200, 100):up(), is_player),
            ai.go_to_target(id, 30),
            bonk_bot.attack(id),
        },
        bonk_bot.patrol(id)
    }
end

function bonk_bot.spin_once(id, args)
    local bh = stack.ensure(nw.component.behavior, id, bonk_bot.behavior(id))
    ai.run(bh)
end

function bonk_bot.spin()
    for id, args in stack.view_table(nw.component.script("bonk_bot")) do
        bonk_bot.spin_once(id, args)
    end
end

local shoot_bot = {}

function shoot_bot.shoot(id)
    return
    ai.sequence {
        ai.action(stack.set, nw.component.puppet_state, id, "shoot"),
        ai.wait_until(
            ai.condition(function() return puppet_animator.is_done(id) end)
        ),
        ai.wait(1.0),
    }

end

function shoot_bot.behavior(id)
    return ai.select {
        ai.fail(
            ai.action(puppet_animator.ensure, id, "idle")
        ),
        shoot_bot.shoot(id),
        bonk_bot.patrol(id)
    }
end

function shoot_bot.spin_once(id)
    local bh = stack.ensure(nw.component.behavior, id, shoot_bot.behavior(id))
    ai.run(bh)
end

function shoot_bot.spin()
    for id, args in stack.view_table(nw.component.script("shoot_bot")) do
        shoot_bot.spin_once(id, args)
    end
end

local cloak = {}

function cloak.jump_hit(id)
    return
    ai.sequence{
        ai.action(function()
            local m = stack.get(nw.component.mirror, id)
            local g = stack.get(nw.component.gravity, id)
            if not g then return end
            local sx = m and -1 or 1
            local h = 50
            motion.jump(id, h)
            local t = motion.jump_time_to_ground(h, g.y)
            local ms = stack.get(nw.component.move_speed, id) or 0
            local dx = 50
            local vx = dx / t
            local intent = sx * vx / ms 
            stack.set(nw.component.move_intent, id, intent)
            motion.clear_on_ground(id)
        end),
        ai.action(stack.set, nw.component.puppet_state, id, "prepare_jump_hit"),
        ai.wait_until(
            ai.condition(function()
                return motion.is_on_ground(id)
            end)
        ),
        ai.action(function()
            stack.set(nw.component.puppet_state, id, "action_jump_hit")
            stack.set(nw.component.move_intent, id, 0)
        end),
        ai.wait_until(
            ai.condition(function() return puppet_animator.is_done(id) end)
        ),
        ai.action(stack.set, nw.component.puppet_state, id, "recover_jump_hit"),
        ai.wait(0.5)
    }
end

function cloak.hit(id)
    return
    ai.sequence {
        ai.set(nw.component.puppet_state, id, "prepare_hit"),
        ai.wait(0.5),
        ai.set(nw.component.puppet_state, id, "action_hit"),
        ai.wait_until_puppet_done(id),
        ai.set(nw.component.puppet_state, id, "recover_hit"),
        ai.wait(0.5)
    }
end

function cloak.behavior(id)
    return ai.select {
        ai.shuffle_select(
            {
                cloak.hit(id),
                cloak.jump_hit(id)
            },
            {60, 30}
        ),
        bonk_bot.patrol(id)
    }
end

function cloak.spin_once(id)
    local bh = stack.ensure(nw.component.behavior, id, cloak.behavior(id))
    ai.run(bh)
end

function cloak.spin()
    for id, args in stack.view_table(nw.component.script("cloak")) do
        cloak.spin_once(id, args)
    end
end

local script = {}

function script.spin()
    player.spin()
    player_boxer.spin()
    patrol_box.spin()
    edge_patrol.spin()
    door.spin()
    bonk_bot.spin()
    shoot_bot.spin()
    cloak.spin()

    for id, _ in stack.view_table(nw.component.reset_script) do
        stack.remove(nw.component.behavior, id)
    end
    stack.destroy_table(nw.component.reset_script)
end

return script 