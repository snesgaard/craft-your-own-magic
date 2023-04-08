local combat = require "combat"
local gui = require "gui"

local target = {}

function target.get_same_team(ecs_world, id)
    return ecs_world:get(nw.component.player_team, id) and nw.component.player_team or nw.component.enemy_team
end

function target.get_opposite_team(ecs_world, id)
    return ecs_world:get(nw.component.player_team, id) and nw.component.enemy_team or nw.component.player_team
end

function target.get_team(ecs_world, id, is_same)
    if is_same then
        return target.get_same_team(ecs_world, id)
    else
        return target.get_opposite_team(ecs_world, id)
    end
end

function target.get_targets_in_order(ecs_world, team_comp)
    return ecs_world
        :get_component_table(team_comp)
        :keys()
        :filter(function(id) return combat.core.is_alive(ecs_world, id) end)
        :sort(function(a, b)
            local pa = math.abs(ecs_world:get(nw.component.board_index, a) or 0)
            local pb = math.abs(ecs_world:get(nw.component.board_index, b) or 0)
            return pa < pb
        end)
end

function target.get_targets(ecs_world, user, side)
    local is_player = ecs_world:get(nw.component.player_team, user)
    local own_team = is_player and nw.component.player_team or nw.component.enemy_team
    local other_team = is_player and nw.component.enemy_team or nw.component.player_team
    local team_comp = side == "same" and own_team or other_team
    return target.get_targets_in_order(ecs_world, team_comp)
end

local target_types = {}

target_types["all/enemy"] = function(ecs_world, user)
    return list(combat.target.get_targets(ecs_world, user))
end

target_types["single/enemy"] = function(ecs_world, user)
    return combat.target.get_targets(ecs_world, user):map(list)
end

target_types["single/enemy/random"] = function(ecs_world, user)
    return list(combat.target.get_targets(ecs_world, user):shuffle())
end

target_types["self"] = function(ecs_world, user)
    return list(list(user))
end

local function target_types_from_string(ecs_world, user, str)
    local f = target_types[str]
    if not f then errorf("Unknown target type %s", str) end
    return f(ecs_world, user)
end

local function is_player_controlled() return true end

local player = {}

function player.component(ecs_world, user, target_type)
    local candidates = target_types_from_string(ecs_world, user, target_type)
    return ecs_world:entity()
        :set(nw.component.drawable, nw.drawable.target_marker)
        :set(nw.component.color, 0.1, 0.2, 0.8)
        :set(nw.component.layer, 3)
        :set(nw.component.keybinding, {increase="right", decrease="left"})
        :set(nw.component.linear_menu_state, candidates)
        :set(is_player_controlled)
end

function player.is_cancel(target_data)
    return gui.menu.is_cancel(target_data)
end

function player.is_done(target_data)
    return gui.menu.is_done(target_data)
end

function player.get(target_data)
    return gui.menu.get_selected_item(target_data)
end

local ai = {}

function ai.component(ecs_world, user, target_type)
    local candidates = target_types_from_string(ecs_world, user, target_type)
    return {
        target = candidates:head(),
        is_ai = true
    }
end

function ai.get(target_data)
    return target_data.target
end


-- TARGETING API STUFF

function target.component(ecs_world, user, ability_request)
    local ability = ability_request.ability
    if not ability then return end
    local target_type = ability.target or "single/enemy"

    if ecs_world:get(nw.component.player_team, user) then
        return player.component(ecs_world, user, target_type)
    else
        return ai.component(ecs_world, user, target_type)
    end
end

function target.is_cancel(target_data)
    if not target_data then return false end

    if not target_data.is_ai then
        return player.is_cancel(target_data)
    end
end

function target.is_done(target_data)
    if not target_data then return true end

    if not target_data.is_ai then
        return player.is_done(target_data)
    else
        return true
    end
end

function target.get(target_data)
    if not target_data then return end

    if not target_data.is_ai then
        return player.get(target_data)
    else
        return ai.get(target_data)
    end
end

return target