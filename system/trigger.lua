local Base = require "system.base"
local trigger = Base()

function trigger:should(item, other)
    if not self:peek_should(item, other) then return false end

    entity_dict[other] = true
    return true
end

function trigger:peek_should(item, other)
    local entity_dict = item:ensure(nw.component.trigger_once_pr_entity)

    return not entity_dict[other]
end

function trigger:update(dt, ecs_world)
    local timer_tables = ecs_world:get_component_table(
        nw.component.trigger_on_interval
    )
    for id, timer_table in pairs(timer_tables) do
        local trig_table = ecs_world:ensure(
            nw.component.trigger_once_pr_entity, id
        )

        for id, value in pairs(trig_table) do
            if value and not timer_table.timers[id] then
                 timer_table.timers[id] = nw.component.timer(timer_table.interval)
            end
        end

        for target, timer in pairs(timer_table.timers) do
            timer:update(dt)
            if timer:done() then
                trig_table[target] = nil
                timer_table[target] = nil
            end
        end
    end
end

return trigger
