local combat = {}

function combat.damage(target, damage)
    if stack.get(nw.component.immune("damage"), target) then return end

    local hp = stack.get(nw.component.health, target)
    if not hp then return end

    local real_damage = math.min(damage, hp.max)
    local next_hp = hp.value - real_damage

    local info = {
        damage = real_damage,
        target = target
    }

    event.emit("damage", info)
    stack.set(nw.component.health, next_hp, hp.max)
    return info
end

function combat.knockback(target, knockback)
    if not stack.get(nw.component.health, target) then
        if not stack.ensure(nw.component.immune("knockback"), target, true) then
            return
        end
    elseif stack.get(nw.component.immune("knockback"), target) then
        return
    end

    collision.move(target, knockback, 0)
end

function combat.stun(target)
    if stack.get(nw.component.immune("stun"), target) then return end

    stack.set(nw.component.reset_script, target)
    stack.set(nw.component.is_sensor_in_contact, target)
end

function combat.is_stunned(target)
    local is_stunned = stack.get(nw.component.is_stunned, target)
    if not is_stunned then return false end

    return not timer.is_done(is_stunned)
end

return combat