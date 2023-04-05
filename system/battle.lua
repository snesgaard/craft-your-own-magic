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

local function combat_round(ecs_world, id)
    -- TODO; add ids nd ecs worlds to these or make IDS pr default
    local data = ecs_world:entity(id)
    if not data:ensure(combat.turn.round_begin, ecs_world) then return end
    if not data:ensure(combat.turn.player_turn, ecs_world) then return end
    if not data:ensure(combat.turn.enemy_turn, ecs_world) then return end
    if not data:ensure(combat.turn.round_end, ecs_world) then return end
    return true
end

function logic.spin(ecs_world)
    local id = "combat"
    if combat_round(ecs_world, id) then
        ecs_world:destroy(id)
    end
end

local api = {}

function api.setup(ecs_world)
    local player = ecs_world:entity("player")
        :set(nw.component.health, 10)
        :set(nw.component.player_team)
        :assemble(board.move_to_index, -1)
        :set(nw.component.drawable, nw.drawable.board_actor)
        :set(nw.component.deck,
            list(
                ability.attack,
                ability.attack,
                ability.attack,
                ability.attack,
                ability.attack,
                ability.heal,
                ability.heal,
                ability.heal,
                ability.heal,
                ability.heal
            )
        )
        :set(nw.component.energy, 3)
        :set(combat.status.strength, 3)

    ecs_world:entity("badboi")
        :set(nw.component.health, 10)
        :set(nw.component.enemy_team)
        :assemble(board.move_to_index, 1)
        :set(nw.component.mouse_rect, -10, -50, 20, 50)
        :set(nw.component.ai_deck, require "ability.cultist")
        :set(nw.component.drawable, nw.drawable.board_actor)
        :set(combat.status.poison, 4)

    ecs_world:entity()
        :set(nw.component.health, 7)
        :set(nw.component.enemy_team)
        :assemble(board.move_to_index, 2)
        :set(nw.component.mouse_rect, -10, -50, 20, 50)
        :set(nw.component.drawable, nw.drawable.board_actor)

    ecs_world:entity()
        :set(nw.component.health, 5)
        :set(nw.component.enemy_team)
        :assemble(board.move_to_index, 3)
        :set(nw.component.mouse_rect, -10, -50, 20, 50)
        :set(nw.component.drawable, nw.drawable.board_actor)
    
    ecs_world:entity("box")
        :set(nw.component.position, 100, 400)
        :set(nw.component.drawable,      nw.drawable.ellipse)
        :set(nw.component.scale, 100, 100)
        :set(nw.component.color, 1, 0, 0, 0.5)
        :set(nw.component.layer, 1)
    
    ecs_world:entity("energy")
        :set(nw.component.drawable, nw.drawable.energy_meter)
        :set(nw.component.layer, 1)
        :set(nw.component.parent, "player")
    
    combat.deck.setup_from_deck(ecs_world, "player")
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