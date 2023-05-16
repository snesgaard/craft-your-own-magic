local state_resolver = {}

function state_resolver.idle(id, state_map, state)
    return input.get_direction_x() ~= 0 and state_map.walk or state_map.idle
end

function state_resolver.DEFAULT(id, state_map, state)
    return state_map[state.name]
end

local sprite_state = {}

function sprite_state.spin_once(id, state, dt)
    local state_map = stack.get(nw.component.sprite_state_map, id) or dict()
    local state_time = state.time
    
    local f = state_resolver[state.name] or state_resolver.DEFAULT
    local video = f(id, state_map, state)
    if not video then return end
    local time = clock.get() - state_time

    local frame = video:frame(time)
    if not frame then return end

    -- Set frame
    stack.set(nw.component.frame, id, frame)

    -- Slice collision detection
    for key, slice in pairs(frame.slices) do
        --collision.check_in_entity_frame(id, frame:get_slice(key, "body"))
    end
end 

function sprite_state.spin()
    for _, dt in event.view("update") do
        for id, state in stack.view_table(nw.component.sprite_state) do
            sprite_state.spin_once(id, state, dt)
        end
    end
end

return sprite_state