
local collision_resolver = {}

function collision_resolver.already_processed(item, other, owner, target)
    local r = stack.ensure(nw.component.hit_registry, item)
    if r[other] then return true end
    r[other] = true
end

function collision_resolver.damage(item, other, owner, target)
    local damage = stack.get(nw.component.damage, item)
    local hp = stack.get(nw.component.health, target)

    if not damage or not hp then return end
    if stack.get(nw.component.player_controlled, item) == stack.get(nw.component.player_controlled, target) then
        return
    end
    
    local info = combat.damage(target, damage)
    if info and info.damage > 0 then combat.stun(target) end
end

function collision_resolver.knockback(item, other, owner, target, colinfo)
    local damage = stack.get(nw.component.damage, item)
    local hp = stack.get(nw.component.health, target)
    if not damage or not hp then return end
    if stack.get(nw.component.player_controlled, item) == stack.get(nw.component.player_controlled, target) then
        return
    end

    local o = stack.get(nw.component.position, owner) or vec2()
    local t = stack.get(nw.component.position, target) or vec2()

    local dx = t.x - o.x
    local knockback = 1 * dx / math.abs(dx)
    combat.knockback(target, knockback)
end

function collision_resolver.handle_collision(item, other, colinfo)
    local owner = stack.get(nw.component.owner, item) or item
    local target = other
    local name = stack.get(nw.component.name, item)

    local magic = stack.get(nw.component.magic, item)

    -- TODO for now we just handle direct processing
    -- A more sophisticaed approach might be needed if incinvibility needs to be handled or something like
    -- multiple hitboxes referring to the same health
    if collision_resolver.already_processed(item, other) then return end

    if stack.get(nw.component.breaker, item) and stack.get(nw.component.breakable, other) then
        stack.destroy(other)
    end

    if stack.get(nw.component.damage, item) and stack.get(nw.component.switch, other) ~= nil then
        stack.map(nw.component.switch_state, other, function(v) return not v end)
    end

    collision_resolver.damage(item, other, owner, target, colinfo)
    collision_resolver.knockback(item, other, owner, target, colinfo)
    
end

function collision_resolver.spin()
    for _, ax, ay, collisions in event.view("move") do
        for _, colinfo in ipairs(collisions) do
            collision_resolver.handle_collision(colinfo.item, colinfo.other, colinfo)
        end
    end
end

return collision_resolver