local timer = require "system.timer"

T("timer", function(T)
    local ctx = TestContext.create()
    local ecs_world = nw.ecs.entity.create()

    local timer_entity = ecs_world:entity()
        :set(nw.component.timer, 2.0)

    T("update_noop", function(T)
        timer.update(ctx, 1.0, ecs_world)
        T:assert(ctx.events:size() == 0)
        timer.update(ctx, 10.0, ecs_world)
        T:assert(ctx.events:size() == 1)
        T:assert(ctx.events:head().key == "timer_completed")
    end)

    T("complete_with_event_data", function(T)
        local custom_event = {}
        timer_entity:set(nw.component.event_on_timer_complete, custom_event)
        timer.update(ctx, 10.0, ecs_world)
        T:assert(ctx.events:size() == 2)
        T:assert(ctx.events:tail().key == custom_event)
    end)

    T("complete_with_event_function", function(T)
        local custom_event = {}
        timer_entity:set(nw.component.event_on_timer_complete, function()
            return custom_event
        end)
        timer.update(ctx, 10.0, ecs_world)
        T:assert(ctx.events:size() == 2)
        T:assert(ctx.events:tail().key == custom_event)
    end)

    T("die_on_complete", function(T)
        timer.timer_completed(ctx, timer_entity.id, ecs_world)
        T:assert(ctx.events:size() == 0)

        timer_entity:set(nw.component.die_on_timer_complete)
        timer.timer_completed(ctx, timer_entity.id, ecs_world)
        T:assert(ctx.events:size() == 1)
        T:assert(ctx.events:head().key == "destroy")
    end)
end)
