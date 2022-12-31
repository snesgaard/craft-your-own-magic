local system = require "system"

local function system_runner(ctx, ecs_world)
    ctx.sys_obs = system.observables_and_system(ctx)

    while ctx:is_alive() do
        system.handle_observables(ctx, ctx.sys_obs, ecs_world)
        ctx:yield()
    end
end

T("test_system", function(T)
    local ecs_world = nw.ecs.entity.create()
    local world = nw.ecs.world()
    local ctx = world:push(system_runner, ecs_world)
    T:assert(ctx.sys_obs:size() == system.order:size())

    T("update_with_timer", function(T)
        local item = ecs_world:entity():set(nw.component.timer, 1)

        world:emit("update", 1):spin()

        T:assert(item:get(nw.component.timer):done())
    end)


end)
