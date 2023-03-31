local combat = require "combat"

local attack = {
    name = "Attack",
    target = "single",
    action = function(ecs_world, id, target)
        combat.core.damage(ecs_world, target, 1)
        return true
    end
}

local heal = {
    name = "Heal",
    target = "single",
    side = "same",
    action = function(ecs_world, id, target)
        combat.core.heal(ecs_world, target, 1)
        return true
    end
}

return {attack=attack, heal=heal}