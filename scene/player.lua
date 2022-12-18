local system = require "system"

local function player_control(ctx, entity)

    local update = ctx:listen("update"):collect()
    local jump = ctx:listen("keypressed")
        :filter(function(k) return k == "space" end)
        :latest()

    local speed = 200

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            local x_dir = nw.system.input().x()
            nw.system.collision(ctx):move(entity, x_dir * speed * dt, 0)
        end

        if jump:pop() then
            nw.system.jump(ctx):request(entity, 50)
        end

        ctx:yield()
    end
end

return function(ctx)
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.system.collision().get_bump_world(ecs_world)

    local obs = system.observables_and_system(ctx)

    local draw = ctx:listen("draw"):collect()

    ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            0, 300, spatial(0, 0, 1000, 100)
        )
        :set(nw.component.is_terrain)

    ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            300, 200, nw.component.hitbox(40, 100)
        )
        :set(nw.component.gravity)
        :assemble(
            nw.system.script().set, player_control
        )
        :set(nw.component.jump, 100)


    while ctx:is_alive() do
        system.handle_observables(ctx, obs, ecs_world)

        for _, _ in ipairs(draw:pop()) do
            bump_debug.draw_world(bump_world)
        end

        ctx:yield()
    end
end
