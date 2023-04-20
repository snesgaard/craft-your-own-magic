local combat = require "combat"
local anime = require "animation_util"

local attack = {
    name = "Attack",
    power = 1,
    target = "single/enemy",
    attack = {
        type = "attack",
        power = 1
    },
    run = function(ecs_world, data_id, user, targets, ability)
        return anime.generic_cast(ecs_world, data_id, user, function()
            combat.core.resolve(ecs_world, user, targets, ability.attack)
        end)
    end
}

local buff = {
    name = "Cultist Power",
    target = "self",
    exhaust = true,
    innate = true,
    status = {
        type = "status",
        status = "cultist_power",
        power = 2,
    },
    run = function(ecs_world, data_id, user, targets, ability)
        return anime.generic_cast(ecs_world, data_id, user, function()
            combat.core.resolve(ecs_world, user, targets, ability.status)
        end)
    end
}

local dagger_spray = {
    name = "Dagger Spray",
    target = "all/enemy",
    attack = {
        type="attack",
        power=6
    },
    heal = {
        type="heal",
        power=2
    },
    run = function(ecs_world, data_id, user, targets, ability)
        local data = ecs_world:entity(data_id)

        local spray_animation = data:ensure(animation.play)
        combat.core.resolve_node(ecs_world, user, targets, ability.attack)

        combat.core.resolve_single(ecs_world, user, user, ability.heal)
    end,
}

return list(buff, attack)
