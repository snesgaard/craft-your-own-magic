local combat = require "system.combat"
local effect = require "effect"

local event = {trigger_explosion = {}}

local assemble = {}

function assemble.projectile(entity, x, y, team, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(10, 10), bump_world
        )
        :set(nw.component.is_effect)
        :set(nw.component.team, team)
        :set(nw.component.timer, 1.0)
        :set(nw.component.event_on_timer_complete, event.trigger_explosion)
        :set(
            nw.component.event_on_effect_trigger,
            function(source)
                return event.trigger_explosion, source
            end
        )
        :set(
            nw.component.effect,
            {effect.trigger_on_actor},
            {effect.trigger_on_terrain}
        )
        :set(nw.component.trigger_once_pr_entity)
end

function assemble.explosion(entity, x, y, team, bump_world)
    return entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(100, 100), bump_world
        )
        :set(nw.component.is_effect)
        :set(nw.component.team, team)
        :set(nw.component.timer, 2.0)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.trigger_once_pr_entity)
end

local rules = {}

rules[event.trigger_explosion] = function(ctx, entity, ...)
    ctx:emit("destroy", entity.id)

    local pos = entity:get(nw.component.position)
    local team = entity:get(nw.component.team)
    local bump_world = entity:get(nw.component.bump_world)

    local explosion = entity:world():entity()
        :assemble(assemble.explosion, pos.x, pos.y, team, bump_world)

    ctx:emit("on_trigger_explosion", explosion)
end

local system = {}

system.rules = rules

system.assemble = assemble

return system
