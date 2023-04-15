local combat = require "combat"
local anime = require "animation"

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
        return anime.generic_cast(ecs_world, data_id, user, function()
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
        return anime.generic_cast(ecs_world, data_id, user, function()
            combat.core.resolve(ecs_world, user, targets, ability.heal)
        end)
    end
}

local function read_slice_from_frame(ecs_world, user, sprite_state, slice_name)
    local entity = ecs_world:entity(user)
    local state_map = ecs_world:get(nw.component.sprite_state_map, user)
    if not state_map then return end
    local frame = state_map[slice_name]
    if not frame then return end
    local slice = frame:get_slice(slice_name, "body")
    return slice
end

local function compute_cast_hitbox(ecs_world, user)
    local pos = ecs_world:get(nw.component.position, user) or vec2()
    local cast_slice = read_slice_from_frame(ecs_world, user, "cast", "cast") or spatial()
    return pos + cast_slice:center()
end

local dagger_spray = {
    name = "Dagger Spray",
    attack = {
        type = "attack",
        power = 2
    },
    target = "all/enemy",
    cost = 1,
    sfx = function(ecs_world, user)
        local pos = compute_cast_hitbox(ecs_world, user)
        return sfx.play(ecs_world, sfx.dagger_spray)
            :set(nw.component.position, pos.x, pos.y)
    end,
    run = function(ecs_world, data_id, user, targets, ability)
        return anime.generic_cast(ecs_world, data_id, user, function()
            local data = ecs_world:entity(data_id)            
            combat.core.resolve(ecs_world, user, targets, ability.attack)
            data:ensure(ability.sfx, ecs_world, user)
        end)
    end
}

return {attack=attack, heal=heal, dagger_spray=dagger_spray}