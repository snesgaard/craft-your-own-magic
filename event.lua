local event = {}

function event.on_damage(target, damage)
    return {
        damage = damage,
        target = target
    }
end

return event