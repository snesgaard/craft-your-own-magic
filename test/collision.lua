local collision = require "system.collision_filter_and_response"

T("collision", function(T)
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    local item = ecs_world:entity()
    local other = ecs_world:entity()

    T("non_terrain", function(T)
        T:assert(
            collision.collision_filter(ecs_world, item.id, other.id) == "cross"
        )
    end)

    T("terrain", function(T)
        other:set(nw.component.is_terrain)
        T:assert(
            collision.collision_filter(ecs_world, item.id, other.id) == "slide"
        )
    end)

    T("terrain_bounce", function(T)
        other:set(nw.component.is_terrain)
        item:set(nw.component.bouncy, 0.5)

        T:assert(
            collision.collision_filter(ecs_world, item.id, other.id) == "bounce"
        )
    end)

    T("terrain_ignore", function(T)
        other:set(nw.component.is_terrain)
        item:set(nw.component.ignore_terrain)
        T:assert(
            collision.collision_filter(ecs_world, item.id, other.id) == "cross"
        )
    end)
end)
