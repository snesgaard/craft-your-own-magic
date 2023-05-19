local player_puppet = {}

local horizontal_movement = {}

function horizontal_movement.can_move(state)
    return state.name == "idle"
end

function horizontal_movement.spin(id, state)
    if not horizontal_movement.can_move(state) then return end 

    for _, dt in event.view("update") do
        local dir = stack.get(nw.component.move_intent, id) or 0
        local speed = 50
        collision.move(id, dir * speed * dt, 0)
    end
end

local jump = {}

function jump.can(id, state)
    return motion.is_on_ground(id) and state.name == "idle"
end

function jump.spin(id, state)
    if not jump.can(id, state) then return end

    local intent = stack.get(nw.component.jump_intent, id)
    if not intent or timer.is_done(intent) then return end

    stack.set(nw.component.velocity, id, 0, -100)
    motion.clear_on_ground(id)
    stack.remove(nw.component.jump_intent, id)
end

local flip = {}

function flip.can(id, state)
    return state.name == "idle"
end

function flip.spin(id, state)
    if not flip.can(state) then return end

    local flip_intent = stack.get(nw.component.move_intent, id)
    if not flip_intent or timer.is_done(flip_intent) then return end

    collision.flip_to(id, flip_intent)
    stack.remove(nw.component.move_intent, id)
end

local dash = {}

function dash.position(id)
    return stack.get(nw.component.position, id) or vec2()
end

function dash.position_change(id)
    return vec2((stack.get(nw.component.mirror, id) and -1 or 1) * 50, 0)
end

function dash.skip_motion(owner)
    return weak_assemble(
        {
            {nw.component.skip_motion},
            {nw.component.timer, dash.duration},
            {nw.component.die_on_timer_done},
            {nw.component.target, owner},
            {nw.component.die_on_state_change, owner, "dash"}
        },
        "skip_motion"
    )
end

dash.duration = 0.15

function dash.can(id, state) return state.name == "idle" end

function dash.spin(id, state)
    if state.name == "idle" then
        local intent = stack.get(nw.component.dash_intent, id)
        if not intent or timer.is_done(intent) then return end
        stack.set(nw.component.puppet_state, id, "dash")
    end

    if state.name ~= "dash" then return end

    stack.remove(nw.component.velocity, id)
    stack.ensure(dash.skip_motion, state.data, id)
    
    local p = stack.ensure(dash.position, state.data, id)
    local dp = stack.ensure(dash.position_change, state.data, id)
    local t = clock.get() - state.time

    for _, dt in event.view("update") do
        local next_p = ease.linear(t, p, dp, dash.duration)
        collision.move_to(id, next_p.x, next_p.y)
    end

    if t < dash.duration then return end

    stack.set(nw.component.puppet_state, id, "idle")
end

return player_puppet