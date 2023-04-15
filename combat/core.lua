local energy = require "combat.energy"
local combat = require "combat"
local core = {}

function core.is_alive(ecs_world, id)
    local hp = ecs_world:get(nw.component.health, id)
    return hp and hp.value > 0
end

function core.attack(ecs_world, user, target, damage)
    local str = ecs_world:get(combat.status.strength, user) or 0
    local real_damage = damage + str
    local on_damage = core.damage(ecs_world, target, real_damage)
    if not on_damage then return end
    return nw.system.entity():emit(
        ecs_world, event.on_attack, user, target, on_damage.damage
    )
end

function core.damage(ecs_world, id, damage)
    local hp = ecs_world:get(nw.component.health, id)
    if not hp then return end

    local is_alive = core.is_alive(ecs_world, id)
    local real_damage = math.min(damage, hp.value)
    hp.value = hp.value - real_damage
    
    return nw.system.entity():emit(ecs_world, event.on_damage, id, real_damage, is_alive)
end

function core.heal(ecs_world, user, id, heal)
    local hp = ecs_world:get(nw.component.health, id)
    if not hp then return end

    local next_health = math.min(hp.max, hp.value + heal)
    local real_heal = next_health - hp.value
    hp.value = next_health

    return nw.system.entity():emit(ecs_world, event.on_heal, id, real_heal)
end

function core.turn_begin(ecs_world, is_player)
    local comp = is_player and nw.component.player_team or nw.component.enemy_team
    local entities = ecs_world:get_component_table(comp)
    for id, _ in pairs(entities) do
        local entity = ecs_world:entity(id)
        if entity:has(nw.component.energy) then entity:set(nw.component.energy, 3) end
    end
    return true
end

function core.turn_end() return true end

function core.apply_status(ecs_world, user, target, status, power)
    if not power or power == 0 then return end

    local status_comp = combat.status.from_string(status)
    if not status_comp then
        print("Unknown status", status)
        return
    end

    local value = ecs_world:ensure(status_comp, target)
    local next_value = value + power
    ecs_world:set(status_comp, target, next_value)

    return nw.system.entity():emit(
        ecs_world, event.on_status_apply, user, target, status_comp, power
    )
end

function core.resolve_single(ecs_world, user, target, node)
    if node.type == "attack" then
        return core.attack(ecs_world, user, target, node.power)
    elseif node.type == "heal" then
        return core.heal(ecs_world, user, target, node.power)
    elseif node.type == "status" then
        return core.apply_status(ecs_world, user, target, node.status, node.power)
    else
        log.info(ecs_world, "unknown node type %s", node.type)
    end
end

function core.resolve(ecs_world, user, targets, node)
    local result = list()

    for _, target in ipairs(targets) do
        local r = core.resolve_single(ecs_world, user, target, node)
        if r then table.insert(result, r) end
    end

    return result
end

return core