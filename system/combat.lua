local Base = require "system.base"
local Combat = Base()

function Combat:damage(entity, damage)
    local info = {target = entity, damage_request = damage}

    local hp = entity:get(nw.component.health)

    print("damage", entity, damage)

    local next_hp = entity:maybe_get(nw.component.health)
        :map(function(health)
            local real_damage = math.clamp(damage, 0, hp.value)
            local next_health = health.value - real_damage
            return {
                damage = real_damage,
                health = nw.component.health(next_health, health.max)
            }
        end)
        :visit(function(args)
            info.damage = args.damage
            entity:set(nw.component.health, args.health.value, args.health.max)
        end)


    local should_die_from_hp = next_hp
        :map(function(args) return args.health.value <= 0 end)
        :value_or_default(false)

    local is_brittle = entity:get(nw.component.brittle)

    if is_brittle or should_die_from_hp then info.death = self:die(entity) end

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

function Combat:die(entity)
    local info = {target = entity}
    entity:set(nw.component.dead)

    local on_death = entity:get(nw.component.on_death)
    if on_death then on_death(self.world, entity) end

    self:emit("on_death", info)
    return info
end

return Combat.from_ctx
