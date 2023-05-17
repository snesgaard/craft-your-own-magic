local state_resolver = {}

function state_resolver.idle(id, state_map, state)
    return input.get_direction_x() ~= 0 and state_map.walk or state_map.idle
end

function state_resolver.DEFAULT(id, state_map, state)
    return state_map[state.name]
end

local function slice_ids()
    return {}
end

local function create_slice_hitboxes(id, key, slice, magic)
    -- Slice collision detection
    local slice_ids = stack.ensure(slice_ids, id)
    slice_ids[key] = slice_ids[key] or nw.ecs.id.weak(key)
    local s_id = slice_ids[key]

    local p = stack.get(nw.component.position, id) or vec2()

    stack.set(nw.component.is_ghost, s_id)
    stack.set(nw.component.magic, s_id, magic)
    stack.set(nw.component.name, s_id, key)
    stack.set(nw.component.owner, s_id, id)

    collision.register(s_id, slice)
    collision.warp_to(s_id, p.x, p.y)
    collision.flip_to(s_id, stack.get(nw.component.mirror, id))
    -- Move to check for collision
    local _, _, cols = collision.move(s_id, 0, 0)
end

local function clean_hitboxes(id)
    local slice_ids = stack.ensure(slice_ids, id)
    for _, id in pairs(slice_ids) do stack.destroy(id) end
end

local sprite_state = {}

function sprite_state.spin_once(id, state, dt)
    clean_hitboxes(id)
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


    for key, slice in pairs(frame.slices) do
        create_slice_hitboxes(id, key, frame:get_slice(key, "body"), state.magic)
    end
end 

function sprite_state.spin()
    for _, dt in event.view("update") do
        for id, state in stack.view_table(nw.component.sprite_state) do
            sprite_state.spin_once(id, state, dt)
        end
    end
end

function sprite_state.is_done(id)
    local state = stack.get(nw.component.sprite_state, id)
    if not state then return true end
    local state_map = stack.get(nw.component.sprite_state_map, id)

    local f = state_resolver[state.name] or state_resolver.DEFAULT
    local video = f(id, state_map, state)
    if not video then return end
    local time = clock.get() - state.time
    return video:is_done(time)
end

return sprite_state