local combat = require "combat"

local attack = {
    name = "Attack",
    power = 3,
    target = "single/enemy",
    cost = 1,
    attack = {
        type = "attack",
        power = 3
    },
    run = function(ecs_world, data_id, user, targets, ability)
        combat.core.resolve(ecs_world, user, targets, ability.attack)
        return true
    end
}

local bash = {
    name = "Bash",
    attack = 8,
    status = 2,
    cost = 2,
    target = "single/enemy",
    run = function(ecs_world, data_id, user, targets, ability)
        for _, target in ipairs(targets) do
            combat.core.attack(ecs_world, user, target, ability.attack)
            combat.core.apply_status(ecs_world, user, target, "vulnerable", ability.status)
        end
        return true
    end
}

local heal = {
    name = "Heal",
    heal = 2,
    target = "self",
    cost = 1,
    run = function(ecs_world, data_id, user, targets, ability)
        for _, target in ipairs(targets) do
            combat.core.heal(ecs_world, target, ability.heal)
        end
        return true
    end
}

local dagger_spray = {
    name = "dagger_spray",
    attack = 6,
    target = "all/enemy",
    cost = 1,
    run = function(ecs_world, data_id, user, targets, ability)
        for i = 1, 2 do
            for _, target in ipairs(targets) do
                combat.core.attack(ecs_world, user, target, ability.attack)
            end
        end
        return true
    end
}

return {attack=attack, heal=heal}