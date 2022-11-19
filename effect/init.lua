local combat = require "system.combat"

local effects = {}

function effects.same_team(a, b)
    return a:get(nw.component.team) == b:get(nw.component.team)
end

function effects.damage(source, target, damage)
    if effects.same_team(source, target) then return end

    local health = target:get(nw.component.health)
    if not health then return end
    local real_damage = math.min(health.value, math.max(damage, 0))

    if target:ensure(nw.component.invincible) > 0 then
        real_damage = 0
    end

    local next_health = health.value - real_damage
    target:set(nw.component.health, next_health, health.max)

    local info = {
        damage = real_damage, target = target, health = next_health
    }
    return info
end

function effects.trigger_heal(source, target, effect)
    if not effects.same_team(source, target) then return end
    return combat():heal(target, effect.heal)
end

function effects.trigger_on_terrain(source, target, effect)
    if not target:get(nw.component.is_terrain) then return end
    return true
end

function effects.trigger_on_actor(source, target)
    if not target:get(nw.component.is_actor) then return end
    return true
end

return effects
