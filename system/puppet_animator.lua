local state_resolver = {}

function state_resolver.idle(id, state_map, state)
    local on_ground = motion.is_on_ground(id)
    local move_intent = stack.get(nw.component.move_intent, id) or 0
    if on_ground then
        return move_intent ~= 0 and state_map.walk or state_map.idle
    else
        local v = stack.ensure(nw.component.velocity, id)
        if v.y < 0 then
            return state_map.ascend or state_map.idle
        else
            return state_map.descend or state_map.idle
        end
    end
end

function state_resolver.fly_punch(id, state_map, state)
    if state.args.vertical then
        return state_map.fly_punch_v
    else
        return state_map.fly_punch_h
    end
end

function state_resolver.DEFAULT(id, state_map, state)
    return state_map[state.name]
end

local function slice_ids()
    return {}
end

local function none_filter() return end

local function create_slice_hitboxes(id, key, slice, magic, properties)
    -- Slice collision detection
    local slice_ids = stack.ensure(slice_ids, id)
    slice_ids[key] = slice_ids[key] or nw.ecs.id.weak(key)
    local s_id = slice_ids[key]

    local p = stack.get(nw.component.position, id) or vec2()

    local predefined_c = {
        {nw.component.is_ghost},
        {nw.component.magic, magic},
        {nw.component.name, key},
        {nw.component.ownder, id}
    }

    stack.assemble(predefined_c, s_id)
    stack.assemble(tiled.assemble_from_properties(properties), s_id)

    collision.register(s_id, slice)
    collision.warp_to(s_id, p.x, p.y)
    collision.flip_to(s_id, stack.get(nw.component.mirror, id), none_filter)
    -- Move to check for collision
    local _, _, cols = collision.move(s_id, 0, 0)
end

local function clean_hitboxes(id, frame_slices, magic)
    local slice_ids = stack.ensure(slice_ids, id)
    for _, id in pairs(slice_ids) do
        local prev_magic = stack.get(nw.component.magic, id)
        if prev_magic and prev_magic ~= magic then
            stack.destroy(id)
        else
            collision.unregister(id)
        end
    end
end

local puppet_animator = {}

function puppet_animator.spin_once(id, state, dt)
    local state_map = stack.get(nw.component.puppet_state_map, id) or dict()
    local state_time = state.time
    
    local f = state_resolver[state.name] or state_resolver.DEFAULT
    local video = f(id, state_map, state)
    if not video then return end
    local time = clock.get() - state_time
    
    local frame = video:frame(time)
    if not frame then return end
    
    -- Set frame
    stack.set(nw.component.frame, id, frame)
    
    clean_hitboxes(id, frame.slices, state.magic)
    for key, slice in pairs(frame.slices) do
        create_slice_hitboxes(
            id, key, frame:get_slice(key, "body"), state.magic, frame.slice_data[key]
        )
    end
end

function puppet_animator.spin()
    for _, dt in event.view("update") do
        for id, state in stack.view_table(nw.component.puppet_state) do
            puppet_animator.spin_once(id, state, dt)
        end
    end
end

function puppet_animator.is_done(id)
    local state = stack.get(nw.component.puppet_state, id)
    if not state then return true end
    local state_map = stack.get(nw.component.puppet_state_map, id)

    local f = state_resolver[state.name] or state_resolver.DEFAULT
    local video = f(id, state_map, state)
    if not video then return end
    local time = clock.get() - state.time
    return video:is_done(time)
end

function puppet_animator.ensure(id, key)
    local state = stack.get(nw.component.puppet_state, id)
    if state and state.name == key then return end
    stack.set(nw.component.puppet_state, id, key)
end

return puppet_animator