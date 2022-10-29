local util = {}

function util.test_ecs_world()
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    local platform = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            300, 300, nw.component.hitbox(-200, 0, 400, 100), bump_world
        )
        :set(nw.component.is_terrain)

    local player = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            300, 300, nw.component.hitbox(20, 50), bump_world
        )
        :assemble(
            nw.system.script().set, require "script.player_control"
        )
        :set(nw.component.gravity)
        :set(nw.component.is_actor)

    local other_actor = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            400, 300, nw.component.hitbox(20, 50), bump_world
        )
        :set(nw.component.is_actor)

    return {ecs_world = ecs_world, bump_world = bump_world}
end

return util
