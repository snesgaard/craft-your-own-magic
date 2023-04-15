local assemble = {}

function assemble.base(entity, x, y, number, r, g, b)
    entity
        :set(nw.component.position, x, y)
        :set(nw.component.text, number)
        :set(nw.component.color, r, g, b)
        :set(nw.component.align, "center")
        :set(nw.component.mouse_rect, spatial():expand(100, 100):unpack())
        :set(nw.component.drawable, nw.drawable.text)
        :set(nw.component.layer, 1)
        :set(nw.component.timer, 1.0)
        :set(nw.component.die_on_timer_complete)
end

function assemble.damage(entity, x, y, number)
    assemble.base(entity, x, y, number, 0.8, 0.3, 0.1)
end

function assemble.heal(entity, x, y, number)
    assemble.base(entity, x, y, number, 0.1, 0.8, 0.3)
end

local popup = {}

function popup.spin(ecs_world)
    local t = ecs_world:get_component_table(event.on_damage)
    for _, on_damage in pairs(t) do
        local pos = ecs_world:get(nw.component.position, on_damage.target) or vec2()
        local dx = love.math.random(-10, 10)
        local dy = love.math.random(-10, 10)
        if on_damage.was_alive then
            ecs_world:entity()
                :assemble(assemble.damage, pos.x + dx, pos.y - 25 + dy, on_damage.damage)
        end
    end

    for _, on_heal in pairs(ecs_world:get_component_table(event.on_heal)) do
        print("go healing")
        local pos = ecs_world:get(nw.component.position, on_heal.target) or vec2()
        local dx = love.math.random(-10, 10)
        local dy = love.math.random(-10, 10)
        ecs_world:entity()
            :assemble(assemble.heal, pos.x + dx, pos.y - 25 + dy, on_heal.heal)
    end
end

popup.assemble = assemble

return popup