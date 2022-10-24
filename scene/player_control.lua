local util = require "util"

local system = {
    base = require "system.base",
    misc = require "system.misc"
}


return function(ctx)
    local systems = list(
        nw.system.motion(),
        nw.system.script()
    )

    local system_and_observables = systems:map(function(sys)
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
        end
    end)
end
