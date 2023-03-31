local energy = {}

function energy.can_spent(ecs_world, id, amount)
    local e = ecs_world:get(nw.component.energy, id) or 0
    return amount <= e
end

function energy.spent(ecs_world, id, amount)
    local e = ecs_world:ensure(nw.component.energy, id)
    local next_e = e - amount
    if next_e < 0 then return false end
    ecs_world:set(nw.component.energy, id, next_e)
    return true
end

function energy.refill(ecs_world, id)
    ecs_world:set(nw.component.energy, id, 3)
end

return energy