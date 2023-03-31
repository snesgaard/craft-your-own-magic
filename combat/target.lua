local combat = require "combat"

local target = {}

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