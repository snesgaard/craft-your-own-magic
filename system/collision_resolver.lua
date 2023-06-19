local effects = {}

function effects.damage(user, target, power)
    local hp = stack.get(nw.component.health, target)

    local damage = math.clamp(hp, 0, power)
    local next_hp = hp - damage

    stack.set(nw.component.health, next_hp)

    local info = {
        user = user,
        target = target,
        damage = damage
    }

    event.emit("damage", user, target, damage)

    return damage
end

function effects.attack(user, target, power)
    local str = stack.get(nw.component.strength, user) or 0
    local arm = stack.get(nw.component.armor, target) or 0

    local damage = effects.damage(user, target, power + str - arm)

    event.emit("attack", user, target, damage)

    return damage
end

function effects.test(user, target, power)
    stack.destroy(target)
end

local collision_resolver = {}

function collision_resolver.trigger_effect(effect_id, user_id, target_id)
    if user_id == target_id then return end

    local memory = stack.ensure(nw.component.effect_trigger_memory, effect_id)
    if memory[target_id] then return end
    memory[target_id] = true

    local name = stack.get(nw.component.effect, effect_id)
    if not name then return end

    local effect_func = effects[name]
    if not effect_func then return end

    local power = stack.get(nw.component.power, effect_id) or 0
    effect_func(user_id, target_id, power)
end

function collision_resolver.already_processed(owner, target, item, other)
    local r = stack.ensure(nw.component.hit_registry, item)
    if r[target] then return true end
    r[target] = true
end

function collision_resolver.damage(owner, target, item)
    local damage = stack.get(nw.component.damage, item)
    local hp = stack.get(nw.component.health, target)
    if not damage or not hp then return end
    local real_damage = math.min(hp, damage)
    local next_hp = hp - real_damage
    stack.set(nw.component.health, target, next_hp)

    local info = {
        damage = real_damage,
        target = target,
        owner = owner,
    }

    event.emit("damage", info)

    stack.set(nw.component.reset_script, target)
end

function collision_resolver.handle_collision(item, other, colinfo)
    local owner = stack.get(nw.component.owner, item) or item
    local target = stack.get(nw.component.owner, other) or other
    local name = stack.get(nw.component.name, item)

    local magic = stack.get(nw.component.magic, item)

    if collision_resolver.already_processed(owner, target, item, other) then return end

    if stack.get(nw.component.breaker, item) and stack.get(nw.component.breakable, other) then
        stack.destroy(other)
    end

    if stack.get(nw.component.damage, item) and stack.get(nw.component.switch, other) ~= nil then
        stack.map(nw.component.switch_state, other, function(v) return not v end)
    end

    collision_resolver.damage(owner, target, item)
end

function collision_resolver.spin()
    for _, ax, ay, collisions in event.view("move") do
        for _, colinfo in ipairs(collisions) do
            collision_resolver.handle_collision(colinfo.item, colinfo.other, colinfo)
        end
    end
end

return collision_resolver