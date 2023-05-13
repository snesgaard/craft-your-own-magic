local component = {}

function component.camera_tracking(slack)
    return {
        slack = slack or 0
    }
end

function component.player_state(key)
    return {
        name = key,
        data = nw.ecs.id.weak("statedata"),
        time = clock.get()
    }
end

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

return component