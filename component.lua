local component = {}

function component.camera_tracking(slack)
    return {
        slack = slack or 0
    }
end

function component.player_state(state)
    return state or "idle"
end

return component