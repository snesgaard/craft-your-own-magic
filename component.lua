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
        time = clock.get()
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

function component.skip_motion() return true end

function component.target(...) return list(...) end

function component.die_on_state_change(id, state)
    return {id = id, state = state}
end

function component.is_ghost() return true end

return component