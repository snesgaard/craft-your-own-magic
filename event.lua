local event = {}

function event.on_damage(target, damage, was_alive)
    return {
        damage = damage,
        target = target,
        was_alive = was_alive
    }
end

function event.on_heal(target, heal)
    return {
        heal = heal,
        target = target
    }
end

function event.on_card_draw(user, card, index)
    return {
        user = user,
        card = card,
        index = index
    }
end

function event.on_card_play(user, card, index)
    return {
        user = user,
        card = card,
        index = index
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

function event.on_attack(user, target, damage)
    return {
        user = user,
        target = target,
        damage = damage
    }
end

return event
