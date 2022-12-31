local system = require("system")
local barrel = require "actor.explosive_barrel"

local function system_runner(ctx, ecs_world)
    ctx.sys_obs = system.observables_and_system(ctx)

    while ctx:is_alive() do
        system.handle_observables(ctx, ctx.sys_obs, ecs_world)
        ctx:yield()
    end
end

T("explosive_barrel", function(T)
    local ecs_world = nw.ecs.entity.create()
    local world = nw.ecs.world()
    local ctx = world:push(system_runner, ecs_world)

    local barrel_entity = nw.system.entity():spawn(ecs_world)
        :assemble(barrel.barrel, 0, 0)

    T("die_and_explosion", function(T)
        local on_death = ctx:listen("on_death"):latest()
        local on_spawned_from = ctx:listen("on_spawned_from"):latest()

        nw.system.combat(ctx):damage(barrel_entity, 1)
        world:spin()

        T:assert(on_death:peek())
        T:assert(on_spawned_from:peek())

        local info = on_spawned_from:peek()
        T:assert(info.func == barrel.explosion)
    end)
end)
