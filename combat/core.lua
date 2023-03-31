local energy = require "combat.energy"
local core = {}

function core.is_alive(ecs_world, id)
    local hp = ecs_world:get(nw.component.health, id)
    return hp and hp.value > 0
end

function core.damage(ecs_world, id, damage)
    local hp = ecs_world:get(nw.component.health, id)
    if not hp then return end

    local real_damage = math.min(damage, hp.value)
    hp.value = hp.value - real_damage
    
    nw.system.entity():emit(ecs_world, event.on_damage, id, real_damage)

    return real_damage
end

function core.heal(ecs_world, id, heal)
    local hp = ecs_world:get(nw.component.health, id)
    if not hp then return end

    local next_health = math.min(hp.max, hp.value + heal)
    local real_heal = next_health - hp.value
    hp.value = next_health
    --nw.system.entity():emit(ecs_world, event.on_damage, id, real_damage)

    return real_heal
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

return core