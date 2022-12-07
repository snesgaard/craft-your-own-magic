local Base = require "system.base"
local Combat = Base()

function Combat:damage(entity, damage)
    local hp = entity:get(nw.component.health)
    if not hp then return end
    local real_damage = math.clamp(damage, 0, hp.value)
    local next_value = hp.value - real_damage

    local info = {
        target = entity,
        damage = real_damage,
        damage_request = damage
    }

    entity:set(nw.component.health, next_value, hp.max)

    self:emit("on_damage", info)

    return info
end

function Combat:heal(entity, heal)
    local hp = entity:get(nw.component.health)
    if not hp then return end

    local real_heal = math.clamp(heal, 0, hp.max - hp.value)
    local next_value = hp.value + real_heal
    entity:set(nw.component.health, next_value, hp.max)

    local info = {
        target = entity,
        heal = real_heal,
        heal_request = heal
    }

    self:emit("on_heal", info)

    return info
end

return Combat.from_ctx
