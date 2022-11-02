local Combat = class()

function Combat.create(world)
    return setmetatable({world=world}, Combat)
end

function Combat:emit(...)
    if self.world then self.world:emit(...) end
end


function Combat:deal_damage(target, damage)
    local health = target:get(nw.component.health)
    if not health then return end
    local real_damage = math.min(health.value, math.max(damage, 0))
    local next_health = health.value - real_damage

    target:set(nw.component.health, next_health, health.max)

    local info = {damage = real_damage, target = target, health = next_health}
    self:emit("on_deal_damage", info)
    return info
end

function Combat:heal(target, heal)
    local health = target:get(nw.component.health)
    if not health then return end
    local real_heal = math.max(0, heal)
    local next_health = math.min(health.max, health.value + heal)
    target:set(nw.component.health, next_health, health.max)

    local info = {
        target = target,
        heal = real_heal,
        health = next_health
    }
    self:emit("on_heal", info)
    return info
end

local default_instance = Combat.create()

local Api = class()

function Api.from_ctx(ctx)
    if not ctx then return default_instance end

    local world = ctx.world or ctx
    world[Combat] = Combat.create(world)
    return world[Combat]
end

function Api:__call(ctx) return Api.from_ctx(ctx) end

return setmetatable({}, Api)
