local ui = {}

local function draw_health(entity, health)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    gfx.translate(0, 10)

    local shape = spatial():expand(40, 6)

    local s = health.value / health.max

    gfx.setColor(1, 0.3, 0.1, 0.25)
    gfx.rectangle("fill", shape:unpack())
    gfx.setColor(1, 0.3, 0.1, 0.25)
    gfx.rectangle("fill", shape.x, shape.y, shape.w * s, shape.h)

    gfx.pop()
end

function ui.draw_health_bar(ecs_world)
    local hp = ecs_world:get_component_table(nw.component.health)

    for id, health in pairs(hp) do
        draw_health(ecs_world:entity(id), health)
    end
end

return ui
