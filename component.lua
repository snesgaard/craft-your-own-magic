local component = {}

function component.camera_tracking(slack)
    return {
        slack = slack or 0
    }
end

function component.sprite_state(key)
    return {
        name = key or "idle",
        data = nw.ecs.id.weak("statedata"),
        time = clock.get(),
        magic = {}
    }
end

function component.sprite_state_map(map) return map or dict() end

function component.player_controlled() return true end

function component.on_ground(timeout)
    return {
        timeout = timeout or 0.3,
        time = clock.get()
    }
end

function component.time(t) return t or 0 end

function component.jump_request(timeout)
    function component.sprite_state(key)
        return {
            name = key or "idle",
            data = nw.ecs.id.weak("statedata"),
            time = clock.get(),
            magic = {}
        }
    end
    
    function component.sprite_state_map(map) return map or dict() end
    return {
        time = clock.get(),
        timeout = timeout or 0.3
    }
end

function component.tilelayer(t) return t end

function component.camera_should_track() return true end

function component.timer(duration, time)
    return {
        duration = duration,
        time = time or clock.get()
    }
end

function component.die_on_timer_done() return true end

function component.skip_motion(v) return v or 0 end

function component.target(...) return list(...) end

function component.die_on_state_change(id, state)
    return {id = id, state = state}
end

function component.is_ghost() return true end

function component.magic(m) return m end

function component.effect(e) return e end

function component.power(p) return p or 0 end

component.hitbox_attention = nw.component.relation(function(hitbox_name) return hitbox_name end)

function component.owner(id) return id end

function component.name(n) return n end

function component.effect_trigger_memory() return dict() end

component.puppet = nw.component.relation(function(...) return list(...) end)

component.script = nw.component.relation(function(...) return list(...) end)

function component.move_intent(x) return x or 0 end

function component.move_speed(x) return x or 0 end

function component.puppet_state(key, args)
    return {
        name = key or "idle",
        data = nw.ecs.id.weak("statedata"),
        time = clock.get(),
        magic = {},
        args = args,
    }
end

function component.puppet_state_map(map) return map or dict() end

function component.dash_intent(d)
    local id = nw.ecs.id.weak("dash_intent")
    stack.set(nw.component.timer, id, d or 0.2)
    return id
end

function component.jump_intent(d)
    local id = nw.ecs.id.weak("jump_intent")
    stack.set(nw.component.timer, id, d or 0.2)
    return id
end

function component.attack_intent(d)
    return weak_assemble(
        {
            {nw.component.timer, d or 0.2}
        },
        "attack_intent"
    )
end

function component.cast_intent(d)
    return weak_assemble(
        {
            {nw.component.timer, d or 0.2}
        },
        "cast_intent"
    )
end

function component.hitstun_intent(d)
    return weak_assemble(
        {
            {nw.component.timer, d or 0.2}
        },
        "hitstun_intent"
    )
end

function component.gravity(gx, gy)
    return vec2(gx or 0, gy or 600)
end

function component.punch_intent(is_down, d)
    local duration = d
    if not d then
        duration = is_down and 0.2 or 10000
    end

    local id = {is_down = is_down}

    stack.assemble(
        {
            {nw.component.timer, duration}
        },
        id
    )

    return id
end

component.can_dash = fixed(true)

function component.dash_cooldown(d)
    return weak_assemble(
        {
            {nw.component.timer, d or 0.4}
        },
        "dash_cooldown"
    )
end

function component.breakable(v)
    return v == nil and true or v
end

function component.breaker() return true end

function component.switch(state) return true end

function component.switch_state(state) return state end

function component.jump_extra() return true end

function component.damage(d) return d end

function component.is_terrain() return true end

function component.disable_move(v) return v or 0 end

function component.disable_flip(v) return v or 0 end

function component.debug() return true end

function component.health(h) return h or 0 end

function component.hit_registry() return {} end

function component.node_status() return list() end

function component.text(text) return text or "notext" end

function component.text_opt(opt) return opt end

function component.gui_area(g) return g end

function component.restore_move(v) return v or 0 end

function component.restore_flip(v) return v or 0 end

function component.reset_script() return true end

function component.behavior(b) return b end

function component.hurtbox() return true end

function component.is_stunned(d)
    return weak_assemble(
        {
            {nw.component.timer, d or 0.3}
        },
        "stun_timer"
    )
end

component.resistance = nw.component.relation(function(value, max)
    max = max or value
    return {
        max = max,
        value = value
    }
end)

component.immune = nw.component.relation(function(v)
    return v or 0
end)

component.restore_immune = nw.component.relation(function(v) return v or 0 end)

component.health = component.resistance("health")

return component