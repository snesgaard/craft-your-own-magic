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

return event
