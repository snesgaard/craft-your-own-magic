local system = require("system")
local fireball = require "actor.fireball"

local function system_runner(ctx, ecs_world)
    ctx.sys_obs = system.observables_and_system(ctx)

    while ctx:is_alive() do
        system.handle_observables(ctx, ctx.sys_obs, ecs_world)
        ctx:yield()
    end
end

T("test_fireball", function(T)
    local ecs_world = nw.ecs.entity.create()
    local world = nw.ecs.world()
    local ctx = world:push(system_runner, ecs_world)

    local item = nw.system.entity():spawn(ecs_world)
        :set(nw.component.team, "foobar")
        :assemble(fireball.fireball, 0, 0, 0, 0)

    T("test_explosion_on_timer", function(T)
        local spawn_spy = ctx:listen("on_spawned"):latest()
        world:emit("update", fireball.CONFIG.FIREBALL.DURATION):spin()
        T:assert(spawn_spy:peek())
        T:assert(spawn_spy:peek():get(nw.component.parent) == item.id)
        T:assert(not item:has(nw.component.team))

        local destroy_spy = ctx:listen("on_destroyed"):latest()
        world:emit("update", fireball.CONFIG.EXPLOSION.DURATION):spin()
        T:assert(destroy_spy:peek())
    end)
end)
