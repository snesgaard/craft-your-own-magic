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

    T("trigger_on_collision", function(T)
        local spawn_spy = ctx:listen("on_spawned"):latest()
        local destroy_spy = ctx:listen("on_destroyed"):latest()
        local damage_spy = ctx:listen("on_damage"):latest()
        local health = 100

        local other = nw.system.entity():spawn(ecs_world)
            :assemble(
                nw.system.collision().assemble.init_entity,
                0, 0, nw.component.hitbox(10, 10)
            )
            :set(nw.component.health, health)

        world:emit("update", 0.0):spin()

        T:assert(damage_spy:peek())
        T:assert(spawn_spy:peek())
        T:assert(destroy_spy:peek())

        T:assert(destroy_spy:pop().id == item.id)
        T:assert(damage_spy:pop().damage == fireball.CONFIG.FIREBALL.DAMAGE)
        T:assert(not damage_spy:peek())

        world:emit("update", 0):spin()

        T:assert(damage_spy:peek())
        T:assert(damage_spy:peek().damage == fireball.CONFIG.EXPLOSION.DAMAGE)

        damage_spy:pop()

        world:emit("update", 0):spin()
        T:assert(not damage_spy:peek())
    end)

    T("trigger_then_hit", function(T)
        print("hit test")
        world:emit("update", fireball.CONFIG.FIREBALL.DURATION):spin()

        local actor = nw.system.entity():spawn(ecs_world)
            :assemble(
                nw.system.collision().assemble.init_entity,
                100, 0, nw.component.hitbox(1, 1)
            )
            :set(nw.component.health, 100)

        local damage_spy = ctx:listen("on_damage"):latest()
        local collision_spy = ctx:listen("collision"):latest()
        world:emit("update", 0):spin()
        T:assert(not damage_spy:peek())

        collectgarbage()
        actor:set(nw.component.velocity, -1000, 0)

        world:emit("update", 1):spin()

        print(dict(collision_spy:peek()), actor.id)
        T:assert(damage_spy:peek())
        T:assert(damage_spy:peek().target == actor)
        T:assert(damage_spy:peek().damage == fireball.CONFIG.EXPLOSION.DAMAGE)
    end)
end)
