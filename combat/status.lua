local combat = require "combat"

local status = {}

function status.cultist_power(v) return v or 0 end

function status.vulnerable(v) return v or 0 end

function status.strength(v) return v or 0 end

function status.from_string(str) return status[str] end

function status.turn_begin(ecs_world, id)
    local cultist_power = ecs_world:ensure(status.cultist_power, id)
    combat.core.apply_status(ecs_world, id, id, "strength", cultist_power)
end

return status