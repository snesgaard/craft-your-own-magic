local gui = require "gui"
local combat = require "combat"

local function is_player_controlled(ecs_world, user)
    return ecs_world:get(nw.component.player_team, user)
end

local player = {}

function player.get_abilities_from_cards(ecs_world, user)
    local card_state = ecs_world:ensure(nw.component.player_card_state, user)
    return card_state.hand
end

function player.component(ecs_world, user, index)
    local abilities = player.get_abilities_from_cards(ecs_world, user)
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

function player.is_done(ability_data)
    return gui.menu.is_confirmed(ability_data)
end

function player.get(ability_data)
    local ability, index = gui.menu.get_selected_item(ability_data)
    return {
        ability = ability,
        type = "card",
        index = index,
        is_ai = true
    }
end

function player.reset(ability_data)
    return gui.menu.reset(ability_data)
end

function player.hide(ability_data)
    ability_data:set(nw.component.visible, false)
end

local ai = {}

function ai.component(ecs_world, user)
    local ai = ecs_world:ensure(nw.component.ai_state, user)
    return {
        ability = ai.intent,
        type = "ai_card",
        is_ai = true,
    }
end

function ai.is_done() return true end

function ai.get(ability_data) return ability_data end

local ability_select = {}

function ability_select.component(ecs_world, user)
    if is_player_controlled(ecs_world:entity(user)) then
        return player.component(ecs_world, user)
    else
        return ai.component(ecs_world, user)
    end
end

function ability_select.is_done(ability_data)
    if not ability_data.is_ai then
        return player.is_done(ability_data)
    else
        return ai.is_done(ability_data)
    end
end

function ability_select.get(ability_data)
    if not ability_data.is_ai then
        return player.get(ability_data)
    else
        return ai.get(ability_data)
    end
end

function ability_select.reset(ability_data)
    if not ability_data.is_ai then return player.reset(ability_data) end
end

function ability_select.hide(ability_data)
    if not ability_data.is_ai then player.hide(ability_data) end
    return true
end

return ability_select