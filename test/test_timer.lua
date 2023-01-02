local timer = require "system.timer"

T("test_timer", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity()
        :set(nw.component.timer, 1.0)

    T("timer", function(T)
        T:assert(not item:get(nw.component.timer):done())
        timer():update(1.0, ecs_world)
        T:assert(item:get(nw.component.timer):done())
    end)

    T("die_on_timer_complete", function(T)
        item:set(nw.component.die_on_timer_complete)
        timer():update(1.0, ecs_world)
        T:assert(not item:has(nw.component.timer))
    end)

    T("on_timer_complete", function(T)
        local dst = {}
        item:set(nw.component.on_timer_complete, function() dst.success = true end)
        timer():update(1.0, ecs_world)
        T:assert(dst.success)
    end)

    T("name_timer", function(T)
        local function timer_comp(c) return c end

        T:assert(timer().is_done(item, timer_comp))

        timer().named_timer(item, timer_comp, 3)
        T:assert(not timer().is_done(item, timer_comp))

        timer():update(3, ecs_world)

        T:assert(timer().is_done(item, timer_comp))
    end)
end)
