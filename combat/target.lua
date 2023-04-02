local combat = require "combat"

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

return target