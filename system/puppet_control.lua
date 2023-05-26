local player_puppet = {}

local horizontal_movement = {}

function horizontal_movement.can_move(state)
    return state.name == "idle"
end

function horizontal_movement.spin(id, state)
    if not horizontal_movement.can_move(state) then return end 
    for _, dt in event.view("update") do
        local dir = stack.get(nw.component.move_intent, id) or 0
        local speed = 150
        collision.move(id, dir * speed * dt, 0)
    end
end

local jump = {}

function jump.velocity_from_height_and_gravity(h, g)
    return math.sqrt(2 * h * g)
end

function jump.can(id, state)
    return motion.is_on_ground(id) and state.name == "idle"
end

function jump.spin(id, state)
    if not jump.can(id, state) then return end

    local intent = stack.get(nw.component.jump_intent, id)
    if not intent or timer.is_done(intent) then return end

    local g = stack.ensure(nw.component.gravity, id)
    local h = 40
    local v = jump.velocity_from_height_and_gravity(h, g.y)


    stack.set(nw.component.velocity, id, 0, -v)
    motion.clear_on_ground(id)
    stack.remove(nw.component.jump_intent, id)
end

local flip = {}

function flip.can(id, state)
    return state.name == "idle" or player_puppet.bash.can_flip(id, state)
end

function flip.spin(id, state)
    if not flip.can(id, state) then return end

    for _, dt in event.view("update") do
        local flip_intent = stack.get(nw.component.move_intent, id) or 0
        if flip_intent ~= 0 then collision.flip_to(id, flip_intent < 0) end
    end
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
        stack.remove(nw.component.dash_intent, id)
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


local bash = {}
player_puppet.bash = bash

function bash.can_flip(id, state)
    return state.name ~= "bash" or clock.get() - state.time < 0.1
end

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

function bash.intent(id, state)
    if state.name ~= "idle" then return end

    local intent = stack.get(nw.component.attack_intent, id)
    if not intent or timer.is_done(intent) then return end

    stack.set(nw.component.puppet_state, id, "bash")
    stack.remove(nw.component.attack_intent, id)
end

function bash.spin(id, state)
    bash.intent(id, state)
    if state.name ~= "bash" then return end

    stack.ensure(bash.collision_resolver, state.data, id, state.magic)
    if not puppet_animator.is_done(id) then return end
    stack.set(nw.component.puppet_state, id, "idle")
end

local cast = {}

function cast.can_flip(...) return bash.can_flip(...) end

function cast.intent(id, state)
    if state.name ~= "idle" then return end

    local intent = stack.get(nw.component.cast_intent, id)
    if not intent or timer.is_done(intent) then return end

    stack.set(nw.component.puppet_state, id, "cast")
    stack.remove(nw.component.cast_intent, id)
end

function cast.spin(id, state)
    cast.intent(id, state)
    if state.name ~= "cast" then return end

    if not puppet_animator.is_done(id) then return end
    stack.set(nw.component.puppet_state, id, "idle")
end

local hitstun = {}

function hitstun.position(id)
    return stack.ensure(nw.component.position, id)
end

function hitstun.direction(id)
    print(stack.get(nw.component.mirror, id))
    return stack.get(nw.component.mirror, id) and 1 or -1
end

hitstun.duration = 0.2

function hitstun.intent(id)
    local intent = stack.get(nw.component.hitstun_intent, id)
    if not intent or timer.is_done(intent) then return end
    stack.set(nw.component.puppet_state, id, "hitstun")
    stack.remove(nw.component.hitstun_intent, id)
end

function hitstun.spin(id, state)
    hitstun.intent(id)

    if state.name ~= "hitstun" then return end

    motion.clear_on_ground(id)
    local p = stack.ensure(hitstun.position, state.data, id)
    local dir = stack.ensure(hitstun.direction, state.data, id)
    local t = clock.get() - state.time

    for _, dt in event.view("update") do
        local x = ease.linear(t, p.x, dir * 30, hitstun.duration)
        local y = ease.linear(t, p.y, -10, hitstun.duration)
        collision.move_to(id, x, y)
    end

    if t < hitstun.duration then return end

    stack.set(nw.component.puppet_state, id, "idle")
end

function player_puppet.spin()
    for id, _ in stack.view_table(nw.component.puppet("player")) do
        local state = stack.ensure(nw.component.puppet_state, id)
        hitstun.spin(id, state)
        flip.spin(id, state)
        horizontal_movement.spin(id, state)
        jump.spin(id, state)
        dash.spin(id, state)
        bash.spin(id, state)
        cast.spin(id, state)
    end
end

local puppet_control = {}

function puppet_control.spin()
    player_puppet.spin()
end

return puppet_control