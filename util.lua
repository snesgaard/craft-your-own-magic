local util = {}

function util.test_ecs_world()
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    local platform = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            300, 300, nw.component.hitbox(-2000, 0, 4000, 100), bump_world
        )
        :set(nw.component.is_terrain)

    local player = ecs_world:entity("player")
        :assemble(
            nw.system.collision().assemble.init_entity,
            300, 200, nw.component.hitbox(20, 50), bump_world
        )
        :assemble(
            nw.system.script().set, require "script.player_control"
        )
        :set(nw.component.gravity)
        :set(nw.component.is_actor)
        :set(nw.component.health, 30)

    local other_actor = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            400, 300, nw.component.hitbox(20, 50), bump_world
        )
        :set(nw.component.is_actor)
        :set(nw.component.health, 20)
        :assemble(
            nw.system.script().set, require "script.patrol_fly"
        )
        :set(nw.component.team, "enemy")

    local trap = ecs_world:entity()
        :assemble(
            require("system.trap").assemble.trap, 100, 300, bump_world
        )

    local barrel = ecs_world:entity()
        :assemble(
            require("system.barrel").assemble.barrel, 300, 300, bump_world
        )

    return {ecs_world = ecs_world, bump_world = bump_world}
end

return util
