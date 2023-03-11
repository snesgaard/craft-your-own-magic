local input = {}

function input.keypressed(ecs_world, key)
    return nw.system.entity():emit(ecs_world, nw.component.keypressed, key)
end

function input.keyreleased(ecs_world, key)
    return nw.system.entity():emit(ecs_world, nw.component.keyreleased, key)
end

function input.mousepressed(ecs_world, x, y, button, is_touch)
    return nw.system.entity():emit(ecs_world, nw.component.mousepressed, x, y, button, is_touch)
end

function input.mousereleased(ecs_world, x, y, button, is_touch)
    return nw.system.entity():emit(ecs_world, nw.component.mousereleased, x, y, button, is_touch)
end

function input.mousemoved(ecs_world, x, y, dx, dy)
    return nw.system.entity():emit(
        ecs_world, nw.component.mousemoved, x, y, dx, dy
    )
end

function input.is_pressed(ecs_world, key)
    local t = ecs_world:get_component_table(nw.component.keypressed)
    for _, v in pairs(t) do
        if v == key then return true end
    end

    return false
end

return input