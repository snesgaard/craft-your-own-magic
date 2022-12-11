local trigger = require "system.trigger"

T("test_system_trigger", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity()
    local other = ecs_world:entity()

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
