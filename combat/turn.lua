local cards = require "ability"
local gui = require "gui"
local combat = require "combat"
local action = require "system.action_animation"
local input = require "system.input"

local player = {}

function player.get_abilities_from_cards(ecs_world, user)
    local card_state = ecs_world:ensure(nw.component.player_card_state, user)
    return card_state.hand
end

function player.ability_stage(ecs_world, user, abilities, index)
    return ecs_world:entity()
        :set(nw.component.position, 25, 25)
        :set(nw.component.drawable, nw.drawable.vertical_menu)
        :set(nw.component.linear_menu_state, abilities, index)
        :set(nw.component.linear_menu_to_text, function(item) return item.name end)
        :set(nw.component.no_cancel)
        :set(nw.component.linear_menu_filter, function(item)
            return combat.energy.can_spent(ecs_world, user, 1)
        end)
end

function player.target_stage(ecs_world, user, ability)
    local targets = combat.target.get_targets(ecs_world, user, ability.side)
    return ecs_world:entity()
        :set(nw.component.drawable, nw.drawable.single_target_marker)
        :set(nw.component.color, 0.1, 0.2, 0.8)
        :set(nw.component.layer, 3)
        :set(nw.component.keybinding, {increase="right", decrease="left"})
        :set(nw.component.linear_menu_state, targets, index)
end

function player.play_card(ecs_world, id, user, ability, index, ...)
    if not combat.energy.spent(ecs_world, user, 1) then return true end
    if not ability.action then return true end
    combat.deck.from_hand_to_discard(ecs_world, user, index)
    return ability.action(ecs_world, id, ...)
end

function player.turn(ecs_world, id)
    local user = "player"
    local data = ecs_world:entity(id or "player_turn")

    if input.is_pressed(ecs_world, "return") then return data end
    
    local abilities = data:ensure(player.get_abilities_from_cards, ecs_world, user)
    local ability_stage = data:ensure(
        player.ability_stage,
        ecs_world, user, abilities
    )
    if not gui.menu.is_confirmed(ability_stage) then return end
    local ability, index = gui.menu.get_selected_item(ability_stage)

    local target_stage = data:ensure(player.target_stage, ecs_world, user, ability)

    if gui.menu.is_cancel(target_stage) then
        gui.menu.reset(ability_stage)
        data:remove(player.target_stage)
    end
    if not gui.menu.is_confirmed(target_stage) then return end
    local target = gui.menu.get_selected_item(target_stage)

    data:ensure(action.submit, ecs_world, player.play_card, user, ability, index, target)
    if not action.empty(ecs_world) then return end

    data:destroy()
end

local turn = {}

function turn.turn_begin(ecs_world, team_component)
    local actors = combat.target.get_targets_in_order(ecs_world, team_component)
    for _, id in ipairs(actors) do 
        combat.deck.draw_until(ecs_world, id, 5)
        combat.energy.refill(ecs_world, id)
    end
    return true
end

function turn.turn_end(ecs_world, team_component)
    return true
end

local api = {}

function api.round_begin(ecs_world, id)
    local data = ecs_world:entity(id or "round_begin")
    
    -- prepare AI
    for id, deck in pairs(ecs_world:get_component_table(nw.component.ai_deck)) do
        local entity = ecs_world:entity(id)
        combat.ai.card_state_from_deck(ecs_world, id)
        combat.ai.prepare_next_action(ecs_world, id)
    end
    
    return true
end

function api.player_turn(ecs_world, id)
    local id = id or "player_turn"
    local data = ecs_world:entity(id)
    local team_comp = nw.component.player_team
    if flag(data, "log") then log.info(ecs_world, "player_turn") end
    if not data:ensure(turn.turn_begin, ecs_world, team_comp) then return end
    if not data:ensure(player.turn, ecs_world, team_comp) then return end
    if not data:ensure(turn.turn_end, ecs_world, team_comp) then return end
    return data
end

local turn_taken = nw.component.relation(function(ecs_world, id)
    local action = combat.ai.get_next_action(ecs_world, id)
    local result = combat.ai.play_ability(ecs_world, id, action)
    return true
end)

function api.enemy_turn(ecs_world, id)
    local id = id or "enemy_turn"
    local data = ecs_world:entity(id)

    if flag(data, "log") then log.info(ecs_world, "enemy_turn") end

    local ids = combat.target.get_targets_in_order(ecs_world, nw.component.enemy_team)
    for _, id in ipairs(ids) do
        if not data:ensure(turn_taken:ensure(id), ecs_world, id) then return end
    end

    return true
end

function api.round_end(ecs_world, id)
    return true
end


return api