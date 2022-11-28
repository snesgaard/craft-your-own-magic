local util = require "util"
local system = require "system"
local painter = require "painter"

return function(ctx)
    local system_and_observables = system.full:map(function(sys)
        return {
            observable = sys.observables(ctx),
            system = sys
        }
    end)

    local level = util.test_ecs_world()

    local draw = ctx:listen("draw"):collect()

    local camera = level.ecs_world:entity("camera")
        :set(nw.component.camera)
        :set(nw.component.scale, 2, 2)
        :set(nw.component.position, 400, 300)
        :set(nw.component.target, "player")

    ctx:spin(function(ctx)
        for _, args in ipairs(system_and_observables) do
            args.system.handle_observables(ctx, args.observable, level.ecs_world)
        end

        for _, _ in ipairs(draw:pop()) do
            gfx.push("all")
            nw.system.camera.push_transform(camera)

            painter.draw(level.ecs_world)
            bump_debug.draw_world(level.bump_world)
            system.ui.draw_health_bar(level.ecs_world)
            system.ui.draw_numbers(level.ecs_world)

            gfx.pop()
        end
    end)
end
