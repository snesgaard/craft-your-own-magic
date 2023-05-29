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
        local v = stack.ensure(nw.component.velocity, id)
        v.x = speed * dir
    end
end

local jump = {}

function jump.velocity_from_height_and_gravity(h, g)
    return math.sqrt(2 * h * g)
end

function jump.can(id, state)
    local vy = stack.ensure(nw.component.velocity, id).y
    return (motion.is_on_ground(id) or stack.get(nw.component.jump_extra, id)) and not state.no_jump and vy > -10
end

function jump.extra(id)
    if motion.is_on_ground(id) then stack.set(nw.component.jump_extra, id) end
end

function jump.spin(id, state)
    jump.extra(id)
    if not jump.can(id, state) then return end

    local intent = stack.get(nw.component.jump_intent, id)
    if not intent or timer.is_done(intent) then return end

    local g = stack.ensure(nw.component.gravity, id)
    local h = 40
    local v = jump.velocity_from_height_and_gravity(h, g.y)

    if motion.is_on_ground(id) then
        motion.clear_on_ground(id)
    else
        stack.remove(nw.component.jump_extra, id)
    end

    stack.set(nw.component.velocity, id, 0, -v)
    stack.remove(nw.component.jump_intent, id)
    stack.set(nw.component.puppet_state, id, "idle")
end

local flip = {}

function flip.can(id, state)
    return not state.no_flip
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

function dash.position_change(id, distance, is_vertical)
    local distance = distance or 50
    if is_vertical then
        return vec2(0, -distance)
    else
        return vec2((stack.get(nw.component.mirror, id) and -1 or 1) * distance, 0)
    end
end

function dash.skip_motion(owner, d)
    return weak_assemble(
        {
            {nw.component.skip_motion},
            {nw.component.timer, d or dash.duration},
            {nw.component.die_on_timer_done},
            {nw.component.target, owner},
            {nw.component.die_on_state_change, owner, "dash"}
        },
        "skip_motion"
    )
end

dash.duration = 0.15

function dash.can(id, state)
    local cd = stack.get(nw.component.dash_cooldown, id)
    return state.name == "idle" and stack.get(nw.component.can_dash, id) and (not cd or timer.is_done(cd))
end

function dash.on_ground(id, state)
    if motion.is_on_ground(id) then stack.set(nw.component.can_dash, id) end
end

function dash.spin(id, state)
    dash.on_ground(id)
    
    if dash.can(id, state) then
        local intent = stack.get(nw.component.dash_intent, id)
        if not intent or timer.is_done(intent) then return end
        stack.set(nw.component.puppet_state, id, "dash")
        stack.remove(nw.component.dash_intent, id)
    end

    if state.name ~= "dash" then return end

    stack.remove(nw.component.velocity, id)
    stack.remove(nw.component.can_dash, id)
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
    stack.set(nw.component.dash_cooldown, id)
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
    state.no_flip = not bash.can_flip(id, state)
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

local boxer = {}

boxer.charge = {}

function boxer.charge.can(id, state)
    return state.name == "idle"
end

function boxer.charge.intent(id, state)
    if not boxer.charge.can(id, state) then return end
    
    local intent = stack.get(nw.component.punch_intent, id)
    if not intent or timer.is_done(intent) or not intent.is_down then return end

    stack.set(nw.component.puppet_state, id, "charge")
    stack.remove(nw.component.punch_intent, id)
    stack.ensure(nw.component.velocity, id).x = 0
end

function boxer.charge.spin(id, state)
    boxer.charge.intent(id, state)

    if state.name ~= "charge" then return end
end

boxer.fly_punch = {
    duration = 0.4,
    distance = 100
}

function boxer.fly_punch.can(id, state)
    return state.name == "charge"
end

function boxer.fly_punch.intent(id, state)
    if not boxer.fly_punch.can(id, state) then return end

    local intent = stack.get(nw.component.punch_intent, id)
    if not intent or timer.is_done(intent) or intent.is_down then return end

    if clock.get() - state.time <= 0.4 then
        stack.set(nw.component.puppet_state, id, "idle")
    else
        local vertical = input.get_direction_y() < 0
        stack.set(nw.component.puppet_state, id, "fly_punch", {vertical = vertical})
        stack.remove(nw.component.punch_intent, id)
    end

end

function boxer.fly_punch.spin(id, state)
    boxer.fly_punch.intent(id, state)

    if state.name ~= "fly_punch" then return end
    state.no_flip = true
    state.no_jump = true

    stack.ensure(dash.skip_motion, state.data, id, boxer.fly_punch.duration)
    local p = stack.ensure(dash.position, state.data, id)
    local d = stack.ensure(dash.position_change, state.data, id, boxer.fly_punch.distance, state.args.vertical)
    local t = clock.get() - state.time

    for _, dt in event.view("update") do
        local next_p = ease.outQuad(math.min(t, boxer.fly_punch.duration), p, d, boxer.fly_punch.duration)
        collision.move_to(id, next_p.x, next_p.y)
    end

    if t < boxer.fly_punch.duration then return end

    stack.set(nw.component.puppet_state, id, "idle")
end

boxer.punch = {}

function boxer.punch.can(id, state)
    return state.name == "idle" or state.name == "punch_a" or state.name == "punch_b"
end

function boxer.punch.should(id, state)
    local intent = stack.get(nw.component.attack_intent, id)
    if not intent or timer.is_done(intent) then return end
    stack.remove(nw.component.attack_intent, id)
    return true
end

function boxer.intent(id, state)
    if not boxer.punch.can(id, state) then return end
    if not boxer.punch.should(id, state) then return end
    
    if state.name == "punch_a" then
        stack.set(nw.component.puppet_state, id, "punch_b")
    else
        stack.set(nw.component.puppet_state, id, "punch_a")
    end
end

function boxer.punch.spin(id, state)
    boxer.intent(id, state)
    if state.name ~= "punch_a" and state.name ~= "punch_b" then return end
    stack.ensure(nw.component.velocity, id).x = 0
    if not puppet_animator.is_done(id) then return end

    stack.set(nw.component.puppet_state, id, "idle")
end

function boxer.spin()
    for id, _ in stack.view_table(nw.component.puppet("boxer-player")) do
        local state = stack.ensure(nw.component.puppet_state, id)
        horizontal_movement.spin(id, state)
        flip.spin(id, state)
        jump.spin(id, state)
        dash.spin(id, state)
        boxer.charge.spin(id, state)
        boxer.fly_punch.spin(id, state)
        boxer.punch.spin(id, state)
    end
end

local puppet_control = {}

function puppet_control.spin()
    player_puppet.spin()
    boxer.spin()
end

return puppet_control