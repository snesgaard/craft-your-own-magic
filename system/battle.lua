local input = require "system.input"
local board = require "system.board"
local timer = require "system.timer"
local gui = require "gui"
local combat = require "combat"
local action = require "system.action_animation"
local tween = require "system.tween"
local ability = require "ability"

local component = {}

local cmp = {}

function cmp.equal(a, b) return a == b end

local logic = {}

logic.id = {
    main="logic/main",
    player="logic/player"   
}

function logic.initial_turn_order(ecs_world)
    local players = ecs_world:get_component_table(nw.component.player_team):keys()
    local enemies = ecs_world:get_component_table(nw.component.enemy_team):keys()
    return players + enemies
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

function logic.round_begin(ecs_world)
    local data = ecs_world:entity(logic.id.main)
    if flag(data, "round_begin") then
        log.info(ecs_world, "round begin")
        combat.deck.draw_until(ecs_world, "player", 5)
    end
end

function logic.end_player_turn(card_state)
    card_state.discard = card_state.discard + card_state.hand
    card_state.hand = list()
end

function component.card_select_menu(data, cards)
    return nw.system.parent().spawn(data)
        :set(nw.component.position, 25, 25)
        :set(nw.component.drawable, nw.drawable.vertical_menu)
        :set(nw.component.linear_menu_state, cards)
end

function logic.pick_player_ability(ecs_world, cards)
    local data = ecs_world:entity(logic.id.player)
    local menu = data:ensure(component.card_select_menu, data, cards)

    if input.is_pressed(ecs_world, "b") then 
        gui.menu.unconfirm(menu)
        return
    end

    if gui.menu.is_confirmed(menu) then
        return gui.menu.get_selected_item(menu)
    end
end

function logic.execute_player_ability(ecs_world, ability, index)
    local ability_id = "ability"
    if not ability then
        nw.system.parent().destroy(ecs_world:entity(ability_id))
        return 
    end

    local status = false
    if ability == "attack" then
        local attack = require "ability.attack"
        status = attack(ecs_world, ability_id, "player")
    elseif ability == "heal" then
        local heal = require "ability.heal"
        status = heal(ecs_world, ability_id, "player")
    else
        log.info(ecs_world, "Unknown ability %s", ability)
    end
    
    return status
end

function logic.player_turn(ecs_world)
    local data = ecs_world:entity(logic.id.main)
    if input.is_pressed(ecs_world, "return") or check_flag(data, "player_turn_done") then
        flag(data, "player_turn_done")
        return true 
    end
    
    local card_state = ecs_world:ensure(nw.component.player_card_state, "player")
    local ability, index = logic.pick_player_ability(ecs_world, card_state.hand)
    if not logic.execute_player_ability(ecs_world, ability) then return end

    card_state.hand = card_state.hand:erase(index)
    card_state.discard = card_state.discard:insert(ability)

    nw.system.parent().destroy(ecs_world:entity(logic.id.player))
end

function logic.enemy_turn(ecs_world)
    return true
end

function logic.round_end(ecs_world)
    local data = ecs_world:entity(logic.id.main)
    if flag(data, "round_end") then
        log.info(ecs_world, "round end")
    end

    data:destroy()
end

function component.targets(ecs_world, user, target_type, side)
    local is_player = ecs_world:get(nw.component.player_team, user)
    local own_team = is_player and nw.component.player_team or nw.component.enemy_team
    local other_team = is_player and nw.component.enemy_team or nw.component.player_team
    local team_comp = side == "same" and own_team or other_team
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

function component.ability_select_stage(ecs_world, user, abilities, index)
    print("ability", abilities)
    return ecs_world:entity()
        :set(nw.component.position, 25, 25)
        :set(nw.component.drawable, nw.drawable.vertical_menu)
        :set(nw.component.linear_menu_state, abilities, index)
        :set(nw.component.linear_menu_to_text, function(item) return item.name end)
end

function component.target_select_stage(ecs_world, user, ability, index)
    local targets = component.targets(ecs_world, user, ability.target, ability.side)
    return ecs_world:entity()
        :set(nw.component.drawable, nw.drawable.single_target_marker)
        :set(nw.component.color, 0.1, 0.2, 0.8)
        :set(nw.component.layer, 3)
        :set(nw.component.keybinding, {increase="right", decrease="left"})
        :set(nw.component.linear_menu_state, targets, index)
end

local function run_ability(ecs_world, id, ability, ...)
    if not ability.action then return true end
    return ability.action(ecs_world, id, ...)
end

function logic.handle_player_turn(ecs_world, id, request)
    local user = request.user
    local data = ecs_world:entity(id)

    if input.is_pressed(ecs_world, "return") then return true end

    local ability_stage = data:ensure(
        component.ability_select_stage,
        ecs_world, user, list(ability.heal, ability.attack)
    )
    if not gui.menu.is_confirmed(ability_stage) then return end

    local select_ability, index = gui.menu.get_selected_item(ability_stage)
    local target_stage = data:ensure(
        component.target_select_stage, ecs_world, user, select_ability
    )
    if gui.menu.is_cancel(target_stage) then
        data:remove(component.target_select_stage)
        data:set(
            component.ability_select_stage,
            ecs_world, user, list(ability.heal, ability.attack), index
        )
        return
    end

    if not gui.menu.is_confirmed(target_stage) then return end

    local target = gui.menu.get_selected_item(target_stage)

    local action_stage = data:ensure(action.submit, ecs_world, run_ability, select_ability, index, target)

    if not action.empty(ecs_world) then return end
    
    data:destroy(id)
    -- Queue new turn
    ecs_world:entity():set(nw.component.player_turn, user)

    return true
end

local function should_destroy(id, request) return request.done end

function logic.spin(ecs_world)
    for id, request in pairs(ecs_world:get_component_table(nw.component.player_turn)) do
        if not request.done then
            request.done = logic.handle_player_turn(ecs_world, id, request)
        end
    end

    local to_destroy = ecs_world:get_component_table(nw.component.player_turn):filter(should_destroy)
    for id, _ in pairs(to_destroy) do ecs_world:destroy(id) end
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
    combat.deck.draw_until(ecs_world, "player", 5)
    ecs_world:entity():set(nw.component.player_turn, "player")
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