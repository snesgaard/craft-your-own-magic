local combat = require "combat"
local animation_util = require "animation_util"
local transform = require "system.transform"

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
        return animation_util.generic_cast(ecs_world, data_id, user, function()
            combat.core.resolve(ecs_world, user, targets, ability.attack)
        end)
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
    target = "self",
    cost = 1,
    heal = {
        type = "heal",
        power = 2
    },
    run = function(ecs_world, data_id, user, targets, ability)
        return animation_util.generic_cast(ecs_world, data_id, user, function()
            combat.core.resolve(ecs_world, user, targets, ability.heal)
        end)
    end
}

local dagger_spray = {
    name = "Dagger Spray",
    attack = {
        type = "attack",
        power = 2
    },
    target = "all/enemy",
    cost = 1,
    count = 2,
}

function dagger_spray.run(ecs_world, data_id, user, targets, ability)
    return animation_util.generic_cast(ecs_world, data_id, user, function()
        local data = ecs_world:entity(data_id)            
        combat.core.resolve(ecs_world, user, targets, ability.attack)
        data:ensure(dagger_spray.sfx, ecs_world, user, targets)
    end)
end

function dagger_spray.sfx(ecs_world, user, targets)
    local pos = animation_util.compute_cast_hitbox(ecs_world, user):center()
    return ecs_world:entity()
        :set(nw.component.position, pos.x, pos.y)
        :set(nw.component.dagger_spray_state, user, targets)
        :set(nw.component.layer, painter.layer.effects)
        :set(nw.component.drawable, nw.drawable.dagger_spray)
        :set(nw.component.timer, 0.2)
end

local bouncing_flask = {
    name = "Bouncing Flask",
    cost = 1,
    poison = {
        type = "status",
        status = "poison",
        power = 3
    },
    attack = {
        type = "attack",
        power = 1
    },
    target = "all/enemy",
    bounce_count = 3
}

function bouncing_flask.flask_sfx(ecs_world, user, targets, ability)
    return ecs_world:entity()
        :init(nw.component.bouncing_flask_state, targets, ability.bounce_count, user)
        :init(nw.component.effect, ability.poison, ability.attack)
        :init(nw.component.layer, painter.layer.effects)
        :init(nw.component.drawable, nw.drawable.ellipse)
        :init(nw.component.scale, 10, 10)
end

function bouncing_flask.run(ecs_world, data_id, user, targets, ability)
    local data = ecs_world:entity(data_id)

    ecs_world:set(nw.component.sprite_state, user, "cast")
    local flask_sfx = data:ensure(bouncing_flask.flask_sfx, ecs_world, user, targets, ability)

    if not flask_sfx:get(nw.component.is_done) then return end

    ecs_world:set(nw.component.sprite_state, user, "idle")

    return true
end

return {attack=attack, heal=heal, dagger_spray=dagger_spray, bouncing_flask=bouncing_flask}