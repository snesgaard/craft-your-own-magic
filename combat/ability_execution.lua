local combat = require "combat"

local function spent_energy(ecs_world, user, ability_request)
    if not ability_request.ability then return end
    return combat.energy.spent(ecs_world, user, ability_request.ability.cost or 0)
end

local function run_ability(ecs_world, data_id, user, target, ability_request)
    local ability = ability_request.ability or {}
    if not ability.run then return true end
    if not target then return end
    return ability.run(ecs_world, data_id, user, target, ability)
end

local function discard_if_needed(ecs_world, data_id, user, ability_request)
    if ability_request.type == "card" and ability_request.index then 
        combat.deck.play_card_from_hand(ecs_world, user, ability_request.index)
    end

    return true
end

return function(ecs_world, data_id, user, ability_request, target)
    local data = ecs_world:entity(data_id)

    if not data:ensure(spent_energy, ecs_world, user, ability_request) then return true end
    if not data:ensure(run_ability, ecs_world, data_id, user, target, ability_request) then return false end
    if not data:ensure(discard_if_needed, ecs_world, data_id, user, ability_request) then return false end

    return true
end