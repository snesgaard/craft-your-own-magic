local effects = {}

function effects.same_team(a, b)
    return a:get(nw.component.team) == b:get(nw.component.team)
end

function effects.damage()
    if same_team(source, target) then return end
    return combat.damage(target, effect.damage)
end

function effects.trigger_heal(source, target, effect)
    if not effects.same_team(source, target) then return end
    return combat.heal(target, effect.heal)
end

function effects.trigger_on_terrain(source, target, effect)
    if not target:get(nw.component.is_terrain) then return end
    return true
end

function effects.trigger_on_actor(source, target)
    if not target:get(nw.component.is_actor) then return end
    return true
end

return effects
