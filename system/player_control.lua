local jump = {}

function jump.is_request_active(id)
    local request = stack.get(nw.component.jump_request, id)
    if not request then return false end

    return clock.get() - request.time < request.timeout
end

function jump.can_jump(id) return true end

function jump.spin(id, state)
    jump.input(id, state)

    if not motion.is_on_ground(id) then return end
    if not jump.is_request_active(id) then return end

    stack.set(nw.component.velocity, id, 0, -100)

    motion.clear_on_ground(id)
    stack.remove(nw.component.jump_request, id)
end

function jump.input(id, state)
    for _, key in event.view("keypressed") do
        if key == "space" then stack.set(nw.component.jump_request, id) end
    end
end

local horizontal_movement = {}

function horizontal_movement.can_move(state)
    return state.name == "idle"
end

function horizontal_movement.spin(id, state)
    if not horizontal_movement.can_move(state) then return end

    for _, dt in event.view("update") do
        local x = input.get_direction_x()
        local speed = 50
        collision.move(id, x * speed * dt, 0)
    end
end

local flip = {}

function flip.can_flip(state)
    return state.name == "idle"
end

function flip.spin(id, state)
    if not flip.can_flip(state) then return end

    for _, _ in event.view("update") do
        local x = input.get_direction_x()
        if x < 0 then
            collision.flip_to(id, true)
        elseif 0 < x then
            collision.flip_to(id, false)
        end
    end
end

local dash = {}

function dash.position(id)
    return stack.get(nw.component.position, id) or vec2()
end

function dash.position_change(id)
    return vec2((stack.get(nw.component.mirror, id) and -1 or 1) * 50, 0)
end

dash.duration = 0.15

function dash.can_dash(id, state)
    return state.name == "idle"
end

function dash.input(id, state)
    if not dash.can_dash(id, state) then return end
    for _, key in event.view("keypressed") do
        if key == "d" then stack.set(nw.component.sprite_state, id, "dash") end
    end
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

function dash.spin(id, state)
    dash.input(id, state)

    if state.name ~= "dash" then return end
    -- Remove gravity
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

    stack.set(nw.component.sprite_state, id, "idle")
end

local bash = {}

function bash.collision_resolver(owner, magic, name)
    return weak_assemble(
        {
            {nw.component.hitbox_attention(owner), "bash"},
            {nw.component.magic, magic},
            {nw.component.effect, "test"},
            {nw.component.power, 3},

        },
        "bash"
    )
end

function bash.input(id, state)
    if not motion.is_on_ground(id) then return end
    if state.name ~= "idle" then return end

    for _, key in event.view("keypressed") do
        if key == "a" then
            stack.set(nw.component.sprite_state, id, "bash")
        end
    end
end

function bash.spin(id, state)
    bash.input(id, state)
    if state.name ~= "bash" then return end

    stack.ensure(bash.collision_resolver, state.data, id, state.magic)
    if not sprite_state.is_done(id) then return end

    stack.set(nw.component.sprite_state, id, "idle")
end

local player_control = {}

function player_control.spin()
    for id, _ in stack.view_table(nw.component.player_controlled) do
        local state = stack.ensure(nw.component.sprite_state, id)
        flip.spin(id, state)
        horizontal_movement.spin(id, state)
        jump.spin(id, state)
        dash.spin(id, state)
        bash.spin(id, state)
    end
end

return player_control