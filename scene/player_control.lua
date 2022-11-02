local util = require "util"
local system = require "system"
local health_bar = require "ui.health_bars"

return function(ctx)
    local system_and_observables = system.full:map(function(sys)
        return {
            observable = sys.observables(ctx),
            system = sys
        }
    end)

    local level = util.test_ecs_world()

    local draw = ctx:listen("draw"):collect()

    ctx:spin(function(ctx)
        for _, args in ipairs(system_and_observables) do
            args.system.handle_observables(ctx, args.observable, level.ecs_world)
        end

        for _, _ in ipairs(draw:pop()) do
            bump_debug.draw_world(level.bump_world)
            health_bar.draw_health_bar(level.ecs_world)
        end
    end)
end
