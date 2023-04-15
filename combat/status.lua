local combat = require "combat"

local status = {}

function status.cultist_power_ready() return true end

function status.cultist_power(v) return v or 0 end

function status.vulnerable(v) return v or 0 end

function status.strength(v) return v or 0 end

function status.poison(v) return math.max(v or 0, 0) end

function status.from_string(str) return status[str] end

function status.turn_begin(ecs_world, team_comp)
    for id, poison in ecs_world:join(status.poison, team_comp) do
        status.trigger_poison(ecs_world, id, poison)
        combat.core.apply_status(ecs_world, id, id, "poison", -1)
    end
end

function status.turn_end(ecs_world, team_comp)
    for id, power in ecs_world:join(status.cultist_power, team_comp) do
        local is_ready = ecs_world:get(status.cultist_power_ready, id)
        if is_ready then 
            combat.core.apply_status(ecs_world, id, id, "strength", power)
        else
            ecs_world:set(status.cultist_power_ready, id)
        end
    end
end

function status.trigger_poison(ecs_world, id, poison)
    if not poison or poison <= 0 then return end
    combat.core.damage(ecs_world, id, poison)
end

return status