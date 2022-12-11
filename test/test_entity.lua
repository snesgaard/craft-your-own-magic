local entity = require "system.entity"

T("test_system_entity", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity()
        :set(nw.component.team, "foobar")

    T("spawn_from", function(T)
        local child = entity():spawn_from(item)
        T:assert(child:get(nw.component.team) == item:get(nw.component.team))

        local other_child = entity():spawn_from(item, function(child)
            child:set(nw.component.position, 1, 2)
        end)
        T:assert(other_child:has(nw.component.position))
    end)

    T("destroy", function(T)
        T:assert(ecs_world:has(nw.component.team, item.id))
        entity():destroy(item)
        T:assert(not ecs_world:has(nw.component.team, item.id))
    end)
end)
