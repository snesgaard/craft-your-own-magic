local coleffect = require "system.collision_and_effect"

T("collision_and_effect", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity()
    local other = ecs_world:entity()

    T("collision_filter", function(T)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "cross")

        other:set(nw.component.is_terrain)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "slide")
        T:assert(coleffect().collision_filter(ecs_world, other.id, item.id) == "cross")

        item:set(nw.component.ignore_terrain)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "cross")
    end)

    T("trigger_once_and_timer", function(T)
        T:assert(coleffect(ctx):can_trigger_effect(item, other))
        coleffect(ctx):invoke_effect(function() end, item, other)
        T:assert(not coleffect(ctx):can_trigger_effect(item, other))

        item:set(nw.component.trigger_on_interval, 2.0)

        coleffect(ctx):update(1.0, ecs_world)
        T:assert(not coleffect(ctx):can_trigger_effect(item, other))
        coleffect(ctx):update(2.0, ecs_world)
        T:assert(coleffect(ctx):can_trigger_effect(item, other))
    end)

end)
