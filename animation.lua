local animation = {}

function animation.generic_cast(ecs_world, data_id, user, func)
    local data = ecs_world:entity(data_id)
    local timer = data:ensure(nw.component.timer, 0.35)

    ecs_world:set(nw.component.sprite_state, user, "cast")
    if flag(data, "resolved") and func then func() end
    if not timer:done() then return end
    ecs_world:set(nw.component.sprite_state, user, "idle")
    return true
end

function animation.ballistic_curve(time, init_pos, end_pos, gravity)
    local data = ecs_world
    local c = init_pos
    local a = gravity or vec2(0, 300)
    local b = end_pos - a - c
    return a * time * time + b * time + c
end

function animation.read_slice_from_frame(ecs_world, user, sprite_state, slice_name)
    local entity = ecs_world:entity(user)
    local state_map = ecs_world:get(nw.component.sprite_state_map, user)
    if not state_map then return end
    local frame = state_map[sprite_state]
    if not frame then return end
    local slice = frame:get_slice(slice_name, "body")
    return slice
end

function animation.compute_cast_hitbox(ecs_world, user)
    local pos = ecs_world:get(nw.component.position, user) or vec2()
    local cast_slice = animation.read_slice_from_frame(ecs_world, user, "cast", "cast") or spatial()
    return cast_slice:move(pos.x, pos.y)
end

function animation.compute_body_hitbox(ecs_world, user)
    local pos = ecs_world:get(nw.component.position, user) or vec2()
    local cast_slice = animation.read_slice_from_frame(ecs_world, user, "idle", "body") or spatial()
    print(cast_slice)
    return cast_slice:move(pos.x, pos.y)
end

return animation