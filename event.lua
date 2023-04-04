local event = {}

function event.on_damage(target, damage)
    return {
        damage = damage,
        target = target
    }
end

function event.on_card_draw(user, card)
    return {
        user = user,
        card = card,
    }
end

function event.on_shuffle_draw(user, before, after)
    return {
        user = user,
        before = before,
        after = after
    }
end

function event.on_status_apply(user, target, status_comp, power, prev_value, next_value)
    return {
        user = user,
        target = target,
        status_comp = status_comp,
        power = power,
        prev_value = prev_value,
        next_value = next_value
    }
end

return event
