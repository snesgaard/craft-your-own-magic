local clock = {}

function clock.spin(ecs_world)
    local data = ecs_world:entity("__time__")
    for _, dt in pairs(ecs_world:get_component_table(nw.component.update)) do
        local t = data:ensure(nw.component.time)
        data:set(nw.component.time, t + dt)
    end
end

function clock.get(ecs_world)
    return ecs_world:ensure(nw.component.time, "__time__")
end

return clock