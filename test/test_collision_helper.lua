local coleffect = require "system.collision_helper"

T("test_system_collision_helper", function(T)
    T("collision_filter", function(T)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "cross")

        other:set(nw.component.is_terrain)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "slide")
        T:assert(coleffect().collision_filter(ecs_world, other.id, item.id) == "cross")

        item:set(nw.component.ignore_terrain)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "cross")
    end)
end)
