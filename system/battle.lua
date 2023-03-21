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

function logic.initial_turn_order(ecs_world)
    local players = ecs_world:get_component_table(nw.component.player_team):keys()
    local enemies = ecs_world:get_component_table(nw.component.enemy_team):keys()
    return players + enemies
end

function logic.player_turn(ecs_world, id)
    local data = ecs_world:entity(logic)
    local menu = ecs_world:entity("menu")

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

function component.move_in_tween(parent, user, target)
    local ecs_world = parent:world()
    local user_pos = ecs_world:get(nw.component.position, user)
    local target_pos = ecs_world:get(nw.component.position, target)
    return nw.system.parent().spawn(parent)
        :set(nw.component.tween, user_pos, target_pos, 0.2)
        :set(nw.component.tween_callback, function(_, pos)
            ecs_world:set(nw.component.position, user, pos.x, pos.y)
        end)
end

function component.move_out_tween(parent, user)
    local ecs_world = parent:world()
    local pos = board.world_position(ecs_world, user)
    local user_pos = ecs_world:get(nw.component.position, user)
    local entity = nw.system.parent().spawn(parent)
    if pos:has_value() then
        local end_pos = vec2(pos:value())
        entity
            :set(nw.component.tween, user_pos, end_pos, 0.2)
            :set(nw.component.tween_callback, function(_, p)
                ecs_world:set(nw.component.position, user, p.x, p.y)
            end)
    end
    return entity
end

function logic.attack_action(ecs_world, id, user, target)
    local data = ecs_world:entity(id)
    local move_in = data:ensure(component.move_in_tween, data, user, target)
    if not tween.is_done(move_in) then return end

    if flag(data, "deal_damage") then
        local dmg = love.math.random(1, 3)
        combat.core.damage(ecs_world, target, dmg * 1000)
    end

    local move_out = data:ensure(component.move_out_tween, data, user)
    if not tween.is_done(move_out) then return end

    return true
end

function component.sphere(parent)
    return nw.system.parent().spawn(parent)
        :set(nw.component.drawable, nw.drawable.ellipse)
        :set(nw.component.position, 100, 100)
        :set(nw.component.scale, 1, 1)
end

function component.out_tween(parent)
    return nw.system.parent().spawn(parent)
        :set(nw.component.tween, 1, 100, 1)
        :set(nw.component.tween_callback, function(_, v)
            parent:set(nw.component.scale, v, v)
        end)
end

function component.in_tween(parent)
    return nw.system.parent().spawn(parent)
        :set(nw.component.tween, 100, 1, 1)
        :set(nw.component.tween_callback, function(_, v)
            parent:set(nw.component.scale, v, v)
        end)
end

function logic.run_player_action(ecs_world, id, func, ...)
    local data = ecs_world:entity(id)
    local sphere = data:ensure(component.sphere, data)
    local out_tween = sphere:ensure(component.out_tween, sphere)
    if not tween.is_done(out_tween) then return end
    local in_tween = sphere:ensure(component.in_tween, sphere)
    if not tween.is_done(in_tween) then return end

    func(...)

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
        print("Not player enemy -> skipping")
        return true
    end
end

local api = {}

function logic.spin(ecs_world)
    if api.is_battle_over(ecs_world) then return end
    if not action.empty(ecs_world) then return end

    local turn_order = ecs_world:entity(logic):get(nw.component.turn_order)
    local turn_order = turn_order or logic.initial_turn_order(ecs_world)
    ecs_world:entity(logic):set(nw.component.turn_order, turn_order)

    local next_turn = turn_order:head()

    if not logic.handle_turn(ecs_world, next_turn) then return end

    turn_order = turn_order:body() + list(turn_order:head())
    ecs_world:entity(logic):set(nw.component.turn_order, turn_order)
end


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
    
    ecs_world:entity("box")
        :set(nw.component.position, 100, 400)
        :set(nw.component.drawable,      nw.drawable.ellipse)
        :set(nw.component.scale, 100, 100)
        :set(nw.component.color, 1, 0, 0, 0.5)
        :set(nw.component.layer, 1)

    
    --[[
    action.submit(ecs_world, function(ecs_world)
        local update = ecs_world:get_component_table(nw.component.update)
        local box = ecs_world:entity("box")
        local v = box:ensure(nw.component.position)

        for _, dt in pairs(update) do
            v.x = v.x + 100 * dt
        end

        return v.x > 500
    end)
    ]]--
end

function api.is_team_alive(ecs_world, comp)
    local t = ecs_world:get_component_table(comp)

    for id, _ in pairs(t) do
        if combat.core.is_alive(ecs_world, id) then return true end
    end

    return false
end

function api.is_battle_over(ecs_world)
    return not api.is_team_alive(ecs_world, nw.component.player_team)
        or not api.is_team_alive(ecs_world, nw.component.enemy_team)
end

function api.spin(ecs_world)
    while nw.system.entity():spin(ecs_world) > 0 do
        action.spin(ecs_world)
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