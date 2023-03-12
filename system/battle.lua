local input = require "system.input"
local board = require "system.board"
local timer = require "system.timer"
local gui = require "gui"
local combat = require "combat"

local component = {}

function component.targets(ecs_world, ability)
    local target_com = ability == "attack" and "enemy_team" or "player_team"
    return {
        target_list = ecs_world
            :get_component_table(nw.component[target_com])
            :keys()
            :sort(function(a, b)
                local pa = math.abs(ecs_world:get(nw.component.board_index, a) or 0)
                local pb = math.abs(ecs_world:get(nw.component.board_index, b) or 0)
                return pa < pb
            end)
    }
end

function component.flags(d) return d or {} end



local cmp = {}

function cmp.equal(a, b) return a == b end

local function flag(entity, flag_id)
    local f = entity:ensure(component.flags)
    local v = f[flag_id]
    f[flag_id] = true
    return not v
end

local logic = {}

function logic.init_target_selection(ecs_world)
    local ts = ecs_world:entity(logic):get(component.target_selection)
    if ts then return ts end

    local ts = ecs_world:get_component_table(nw.component.enemy_team):keys()

    ecs_world:entity(logic):set(component.target_selection, ts)


    return ts
end

function logic.initial_turn_order(ecs_world)
    local players = ecs_world:get_component_table(nw.component.player_team):keys()
    local enemies = ecs_world:get_component_table(nw.component.enemy_team):keys()
    return players + enemies
end

function logic.handle_target_selection(ecs_world, target_data)
    local prev_index = target_data.index

    target_data.index = target_data.index or 1
    target_data.index = math.clamp(target_data.index, 1, target_data.target_list:size())

    if input.is_pressed(ecs_world, "left") then
        if target_data.index <= 1 then
            target_data.index = target_data.target_list:size()
        else
            target_data.index = target_data.index - 1
        end
    end

    if input.is_pressed(ecs_world, "right") then
        if target_data.target_list:size() <= target_data.index then
            target_data.index = 1
        else
            target_data.index = target_data.index + 1
        end
    end

    return prev_index ~= target_data.index
end

function logic.player_turn(ecs_world, id)
    local data = ecs_world:entity(logic)
    local menu = ecs_world:entity("menu")

    menu:ensure(nw.component.position, 100, 100)
    menu:ensure(nw.component.linear_menu_state, list("attack", "heal", "defend"))
    menu:ensure(nw.component.drawable, nw.drawable.vertical_menu)

    local ability = gui.menu.get_selected_item(menu)
    if not ability then return end

    if flag(data, "ability_select") then
        print("ability selected", ability)
    end

    local target_data = data:ensure(component.targets, ecs_world, ability)

    if logic.handle_target_selection(ecs_world, target_data) then
        local id = target_data.target_list[target_data.index]
        ecs_world:entity("marker")
            :set(nw.component.parent, id)
            :set(nw.component.color, 0.1, 0.3, 0.8)
    end

    if input.is_pressed(ecs_world, "b") then
        ecs_world:entity("marker"):set(nw.component.parent)
        menu:get(nw.component.linear_menu_state).confirmed = false
        data:remove(component.targets)
        return false
    end


    if not input.is_pressed(ecs_world, "space") then
        return false
    end


    local target_id = target_data.target_list[target_data.index]
    if target_id then
        if ability == "attack" then
            local dmg = love.math.random(1, 3)
            combat.core.damage(ecs_world, target_id, dmg)
        elseif ability == "heal" then
            combat.core.heal(ecs_world, target_id, 10)
        end
    end

    data:destroy()
    menu:destroy()

    return true
end

function logic.enemy_turn(ecs_world, id)
    local data = ecs_world:entity(logic)
    local t = data:ensure(nw.component.timer, 0.3)

    if flag(data, "entry") then
        ecs_world:entity("marker")
            :set(nw.component.parent, id)
            :set(nw.component.color, 0.8, 0.2, 0.1)
        print("enemy_turn_begin", id)
    end

    if not t:done() then return false end

    data:destroy()

    local target_id = ecs_world:get_component_table(nw.component.player_team)
        :keys()
        :shuffle()
        :head()

    if target_id then
        combat.core.damage(ecs_world, target_id, 1)
    else
        print("target not found")
    end

    print("end of enemy turn")

    return true
end

function logic.handle_turn(ecs_world, id)
    if ecs_world:get(nw.component.player_team, id) then
        return logic.player_turn(ecs_world, id)
    elseif ecs_world:get(nw.component.enemy_team, id) then
        return logic.enemy_turn(ecs_world, id)
    else
        print("Not player enemy -> skipping")
        return true
    end
end

function logic.spin(ecs_world)
    local turn_order = ecs_world:entity(logic):get(nw.component.turn_order)
    local turn_order = turn_order or logic.initial_turn_order(ecs_world)
    ecs_world:entity(logic):set(nw.component.turn_order, turn_order)

    local next_turn = turn_order:head()

    if not logic.handle_turn(ecs_world, next_turn) then return end

    turn_order = turn_order:body() + list(turn_order:head())
    ecs_world:entity(logic):set(nw.component.turn_order, turn_order)
end

local api = {}

function api.setup(ecs_world)
    local player = ecs_world:entity("player")
        :set(nw.component.health, 10)
        :set(nw.component.player_team)
        :assemble(board.move_to_index, -1)
        :set(nw.component.drawable, nw.drawable.board_actor)

    ecs_world:entity()
        :set(nw.component.health, 10)
        :set(nw.component.enemy_team)
        :assemble(board.move_to_index, 1)
        :set(nw.component.drawable, nw.drawable.board_actor)

    ecs_world:entity()
        :set(nw.component.health, 7)
        :set(nw.component.enemy_team)
        :assemble(board.move_to_index, 2)
        :set(nw.component.drawable, nw.drawable.board_actor)

    ecs_world:entity()
        :set(nw.component.health, 5)
        :set(nw.component.enemy_team)
        :assemble(board.move_to_index, 3)
        :set(nw.component.drawable, nw.drawable.board_actor)

    ecs_world:entity("marker")
        :set(nw.component.position, 100, 100)
        :set(nw.component.color, 0.1, 0.3, 0.8)
        :set(nw.component.drawable, nw.drawable.target_marker)
        :set(nw.component.layer, 1)
    
    --[[
    ecs_world:entity()
        :set(nw.component.position, 100, 100)
        :set(nw.component.linear_menu_state, list("foo", "bar", "baz"))
        :set(nw.component.drawable, nw.drawable.vertical_menu)
        ]]--
end

function api.spin(ecs_world)
    while nw.system.entity():spin(ecs_world) > 0 do
        logic.spin(ecs_world)
        board.spin(ecs_world)
        combat.spin(ecs_world)
        gui.spin(ecs_world)
        
        timer().spin(ecs_world)
    end
end

return api