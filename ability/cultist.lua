local combat = require "combat"

local attack = {
    name = "Attack",
    power = 1,
    target = "single/enemy",
    run = function(ecs_world, data_id, user, targets, ability)
        for _, target in ipairs(targets) do
            combat.core.attack(ecs_world, user, target, ability.power)
        end
        return true
    end
}

local buff = {
    name = "Cultist Power",
    type = "status",
    status = "cultist_power",
    power = 2,
    target = "self",
    exhaust = true,
    innate = true,
    run = function(ecs_world, data_id, user, targets, ability)
        for _, target in ipairs(targets) do
            combat.core.apply_status(ecs_world, user, target, ability.status, ability.power)
        end
        return true
    end
}

return list(buff, attack)
