local trigger = require "system.trigger"

T("test_system_trigger", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity()
    local other = ecs_world:entity()

    T("trigger_once_and_timer", function(T)
        T:assert(trigger():peek_should(item, other))
        T:assert(trigger():should(item, other))
        T:assert(not trigger():should(item, other))

        item:set(nw.component.trigger_on_interval, 2.0)

        trigger():update(1.0, ecs_world)
        T:assert(not trigger():should(item, other))
        trigger():update(2.0, ecs_world)
        T:assert(trigger():should(item, other))
    end)
end)
