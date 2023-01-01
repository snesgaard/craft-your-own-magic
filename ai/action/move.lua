return function(ctx, entity, target_position, speed)
    local update = ctx:listen("update"):collect()

    local vector_to_target = ctx:listen("moved")
        :filter(function(item) return item.id == entity.id end)
        :latest{entity}
        :map(function()
            return target_position - entity:get(nw.component.position)
        end)
        :latest()

    local distance_to_target = vector_to_target
        :map(vec2().length)
        :latest()

    local function move_on_update(dt)
        local step = speed * dt
        local v = vector_to_target:peek()
        local l = distance_to_target:peek()
        local is_there = l <= step
        if is_there then
            nw.system.collision(ctx):move_to(
                entity, target_position.x, target_position.y
            )
        else
            local s = v * step / l
            nw.system.collision(ctx):move(entity, s.x, s.y)
        end

        return is_there
    end

    local function move_reductor(is_done, dt)
        return is_done or move_on_update(dt)
    end

    return ctx:spin(function()
        return update:pop():reduce(move_reductor, false)
    end)
end
