local input = require "system.input"
local board = require "system.board"
local timer = require "system.timer"
local gui = require "gui"
local combat = require "combat"
local action = require "system.action_animation"
local tween = require "system.tween"

local component = {}

local cmp = {}

function cmp.equal(a, b) return a == b end

local logic = {}

logic.id = "logic"

function logic.initial_turn_order(ecs_world)
    local players = ecs_world:get_component_table(nw.component.player_team):keys()
    local enemies = ecs_world:get_component_table(nw.component.enemy_team):keys()
    return players + enemies
end

function logic.player_turn(ecs_world, id)
    local data = ecs_world:entity(logic)
    local menu = ecs_world:entity("menu")
    local hand = ecs_world:ensure(nw.component.player_card_state, id).hand
    print(hand)

    menu:ensure(nw.component.position, 100, 100)
    local menu_state = menu:ensure(nw.component.linear_menu_state, list("attack", "heal", "pass"))
    menu:ensure(nw.component.drawable, nw.drawable.vertical_menu)

    if not menu_state.confirmed then return end
    local ability = gui.menu.get_selected_item(menu)

    local status = false
    if ability == "attack" then
        local attack = require "ability.attack"
        status = attack(ecs_world, ability, id)
    elseif ability == "heal" then
        local heal = require "ability.heal"
        status = heal(ecs_world, ability, id)
    end

    if status then
        nw.system.entity():destroy(ecs_world, ability)
        menu:destroy()
    end

    return status
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

    ecs_world:entity("marker"):set(nw.component.parent, nil)

    print("end of enemy turn")

    return true
end

function logic.handle_turn(ecs_world, id)
    if not combat.core.is_alive(ecs_world, id) then
        print("Actor is dead: ", id)
        return true
    end

    if ecs_world:get(nw.component.player_team, id) then
        return logic.player_turn(ecs_world, id)
    elseif ecs_world:get(nw.component.enemy_team, id) then
        return logic.enemy_turn(ecs_world, id)
    else
        print("Not player or enemy -> skipping")
        return true
    end
end

function logic.is_team_alive(ecs_world, comp)
    local t = ecs_world:get_component_table(comp)

    for id, _ in pairs(t) do
        if combat.core.is_alive(ecs_world, id) then return true end
    end

    return false
end

function logic.is_battle_over(ecs_world)
    return not logic.is_team_alive(ecs_world, nw.component.player_team)
        or not logic.is_team_alive(ecs_world, nw.component.enemy_team)
end
    
function logic.spin(ecs_world)
    if logic.is_battle_over(ecs_world) then return end
    if not action.empty(ecs_world) then return end

    local turn_order = ecs_world:entity(logic):get(nw.component.turn_order)
    local turn_order = turn_order or logic.initial_turn_order(ecs_world)
    ecs_world:entity(logic):set(nw.component.turn_order, turn_order)

    local next_turn = turn_order:head()

    if not logic.handle_turn(ecs_world, next_turn) then return end

    turn_order = turn_order:body() + list(turn_order:head())
    ecs_world:entity(logic):set(nw.component.turn_order, turn_order)
end

function logic.round_begin(ecs_world)
    local data = ecs_world:entity(logic.id)
    if flag(data, "round_begin") then
        log.info(ecs_world, "round begin")
    end
end

function logic.player_turn(ecs_world)
    local data = ecs_world:entity(logic.id)
    local hand = ecs_world:ensure(nw.component.player_card_state, "player").hand
    local menu = ecs_world:entity("card_menu")
        :assemble(nw.system.parent().set_parent, data)

    menu:ensure(nw.component.position, 25, 25)
    menu:ensure(nw.component.drawable, nw.drawable.vertical_menu)
    local menu_state = menu:ensure(nw.component.linear_menu_state, hand)

    if flag(data, "player_turn") then
        log.info(ecs_world, "hand %s", tostring(hand))
        log.info(ecs_world, "player turn")
    end

    local ability = gui.menu.get_selected_item(menu)
    if not menu_state.confirmed then
        return
    end

    if input.is_pressed(ecs_world, "b") then
        ecs_world:destroy(ability)
        menu_state.confirmed = false
        return
    end

    local status = false
    if ability == "attack" then
        local attack = require "ability.attack"
        status = attack(ecs_world, ability, "player")
    elseif ability == "heal" then
        local heal = require "ability.heal"
        status = heal(ecs_world, ability, "player")
    else
        log.info(ecs_world, "Unknown ability %s", ability)
    end
    
    if status then
        nw.system.parent().destroy(data)
        ecs_world:destroy(ability)
    end

    return status
end

function logic.enemy_turn(ecs_world)
    return true
end

function logic.round_end(ecs_world)
    local data = ecs_world:entity(logic.id)
    if flag(data, "round_end") then
        log.info(ecs_world, "round end")
    end

    data:destroy()
end

function logic.spin(ecs_world)
    if logic.is_battle_over(ecs_world) then return end
    if not action.empty(ecs_world) then return end

    logic.round_begin(ecs_world)

    if not logic.player_turn(ecs_world) then return end
    if not logic.enemy_turn(ecs_world) then return end

    logic.round_end(ecs_world)
end

local api = {}

function api.setup(ecs_world)
    local player = ecs_world:entity("player")
        :set(nw.component.health, 10)
        :set(nw.component.player_team)
        :assemble(board.move_to_index, -1)
        :set(nw.component.drawable, nw.drawable.board_actor)
        :set(nw.component.deck,
            list("attack", "attack", "attack", "attack", "attack")
            + list("heal", "heal", "heal", "heal", "heal")
        )

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
    
    ecs_world:entity("box")
        :set(nw.component.position, 100, 400)
        :set(nw.component.drawable,      nw.drawable.ellipse)
        :set(nw.component.scale, 100, 100)
        :set(nw.component.color, 1, 0, 0, 0.5)
        :set(nw.component.layer, 1)

    combat.deck.setup_from_deck(ecs_world, "player")
    for i = 1, 5 do
        combat.deck.draw_card_from_deck(ecs_world, "player")
    end
end

api.is_team_alive = logic.is_team_alive

api.is_battle_over = logic.is_battle_over

function api.spin(ecs_world)
    while nw.system.entity():spin(ecs_world) > 0 do
        action.spin(ecs_world)
        log.spin(ecs_world)
        tween.spin(ecs_world)
        logic.spin(ecs_world)
        board.spin(ecs_world)
        combat.spin(ecs_world)
        gui.spin(ecs_world)
        
        timer().spin(ecs_world)
    end

    return false
end

return api