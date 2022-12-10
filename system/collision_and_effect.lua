local Base = require "system.base"
local CollisionAndEffect = Base()

function CollisionAndEffect:invoke_effect(func, source, target)
    if not func then return end
    if not self:can_trigger_effect(source, target) then return end
    local entity_dict = source:ensure(nw.component.trigger_once_pr_entity)
    entity_dict[target.id] = true
    return func(colinfo, source, target)
end

function CollisionAndEffect:can_trigger_effect(source, target)
    local entity_dict = source:ensure(nw.component.trigger_once_pr_entity)

    return not entity_dict[target.id]
end

function CollisionAndEffect:on_collision(colinfo)
    local item_effect = colinfo.ecs_world:get(
        nw.component.effect, colinfo.item
    )
    local other_effect = colinfo.ecs_world:get(
        nw.component.effect, colinfo.other
    )

    self:invoke_effect(colinfo, item_effect, colinfo.item, colinfo.other)
    self:invoke_effect(colinfo, other_effect, colinfo.other, colinfo.item)
end

function CollisionAndEffect:update(dt, ecs_world)
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

function CollisionAndEffect.collision_filter(ecs_world, item, other)
    local item = ecs_world:entity(item)
    local other = ecs_world:entity(other)

    if other:has(nw.component.is_terrain) then
        if item:has(nw.component.ignore_terrain) then return "cross" end

        return item:has(nw.component.bouncy) and "bounce" or "slide"
    end

    return "cross"
end

return CollisionAndEffect.from_ctx
