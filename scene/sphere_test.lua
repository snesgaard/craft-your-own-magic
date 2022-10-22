local system = {
    base = require "system.base",
    timer = require "system.timer",
    ball = require "system.ball",
    misc = require "system.misc"
}

return function(ctx)

    local systems = list(
        system.base.system(system.timer),
        system.base.system(system.ball.rules),
        system.base.system(system.misc),
        nw.system.motion()
    )

    local system_and_observables = systems:map(function(sys)
        return {
            observable = sys.observables(ctx),
            system = sys
        }
    end)

    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    ecs_world:entity()
        :assemble(
            system.ball.assemble.ball_projectile,
            100, 100, bump_world
        )
        :set(nw.component.velocity, 1000, 0)

    ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            300, 0, nw.component.hitbox(0, 0, 10, 1000), bump_world
        )

    local draw = ctx:listen("draw"):collect()

    ctx:spin(function(ctx)
        for _, args in ipairs(system_and_observables) do
            args.system.handle_observables(ctx, args.observable, ecs_world)
        end

        for _, _ in ipairs(draw:pop()) do
            bump_debug.draw_world(bump_world)
        end
    end)
end
