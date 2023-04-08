local combat = require "combat"
local action = require "system.action_animation"

local ai = {}

local function should_exhaust(card)
    return card and card.exhaust
end

function ai.card_state_from_deck(ecs_world, id, deck)   
    local deck = deck or ecs_world:get(nw.component.ai_deck, id)
    if not deck then return end
    if ecs_world:has(nw.component.ai_state, id) then return end
    local innate = deck:filter(function(a) return a.innate end)
    local not_innate = deck:filter(function(a) return not a.innate end)
    local draw = innate:shuffle() + not_innate:shuffle()
    ecs_world:set(nw.component.ai_state, id, draw)
end

function ai.advance_action_deck(ecs_world, id)
    local user = ecs_world:entity(id)
    local ai = user:ensure(nw.component.ai_state)

    if should_exhaust(ai.intent) then
        ai.exhaust = ai.exhaust:insert(ai.intent)
    else
        ai.discard = ai.discard:insert(ai.intent)
    end

    if ai.draw:empty() then
        ai.draw = ai.discard:shuffle()
        ai.discard = list()
    end

    ai.intent = ai.draw:head()
    ai.draw = ai.draw:body()

    return ai.discard
end

function ai.get_next_action(ecs_world, id)
    local user = ecs_world:entity(id)
    local ai = user:ensure(nw.component.ai_state)
    return ai.intent
end

function ai.prepare_next_action(ecs_world, id)
    ai.advance_action_deck(ecs_world, id)
    return ai.get_next_action(ecs_world, id)
end

function ai.is_player_controlled(ecs_world, id)
    return ecs_world:get(nw.component.player_team, id)
end

function ai.should_abort(ecs_world, id)
    if not ai.is_player_controlled(ecs_world, id) then return end

    return input.is_pressed(ecs_world, "return")
end

function ai.execute_turn(ecs_world, user)
    -- Setup entity
    local id = string.format("turn:%s", tostring(user))
    local data = ecs_world:entity(id)

    if ai.should_abort(ecs_world, user) then
        data:remove(combat.ability_select.component)
        data:remove(combat.target.component)
        return data
    end

    -- Select ability
    local ability_data = data:ensure(combat.ability_select.component, ecs_world, user)
    if not combat.ability_select.is_done(ability_data) then return end
    local ability = combat.ability_select.get(ability_data)

    -- Select target
    local target_data = data:ensure(combat.target.component, ecs_world, user, ability)
    if combat.target.is_cancel(target_data) then
        data:remove(combat.target.component)
        combat.ability_select.reset(ability_data)
        return
    end
    if not combat.target.is_done(target_data) then return end
    local target = combat.target.get(target_data)

    -- Execute ability
    local action_data = data:ensure(action.submit, ecs_world, combat.ability_execution, user, ability, target)
    if not action.empty(ecs_world) then return end

    -- Clear data if needed
    if ai.is_player_controlled(ecs_world, user) then
        data:destroy()
        return
    else
        return data
    end
end

return ai