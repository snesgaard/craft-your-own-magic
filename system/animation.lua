local dagger = {}

function effect_resolution(ecs_world, id)
    local effects = ecs_world:ensure(nw.component.effect, id)
    local user = ecs_world:ensure(nw.component.user, id)
    local targets = ecs_world:ensure(nw.component.targets, id)
    
    return effects:map(function(effect)
        return combat.core.resolve(ecs_world, user, targets, effect)
    end)
end

function dagger_throw(ecs_world, id, state)
    local data = ecs_world:entity(id)
    local cast = data:ensure(animation.cast)
    if not cast:get(nw.component.is_done) then return end
    local effect = data:ensure(animation.effect_resolve)
    if not effect:get(nw.component.is_done) then return end
    local to_idle = data:ensure(animation.go_to_idle)
    if not to_idle:get(nw.component.is_done) then return end

    data:set(nw.component.is_done)
end

function dual_dagger_throw(ecs_world, id, state)
    local data = ecs_world:entity(id)

    local first_throw = data:ensure(dual_dagger_throw.first_throw)
    if not first_throw:get(nw.component.is_done) then return end

    local second_throw = data:ensure(dual_dagger_throw.second_throw)
    if not second_throw:get(nw.component.is_done) then return end

    data:set(nw.component.is_done)
end

local cast = {}

function cast.spin_once(ecs_world, id, state)
    local data = ecs_world:entity(id)
    if data:get(nw.component.is_done) then return end
    
    local timer = data:ensure(nw.component.timer, 0.35)
    ecs_world:set(nw.component.sprite_state, user, "cast")

    if not timer:done() or not sfx_entity:get(nw.component.is_done) then return end
    ecs_world:set(nw.component.sprite_state, user, "idle")

    data:set(nw.component.is_done)
end

local animation = {}

function animation.spin(ecs_world)
    for id, state in ecs_world:get_component_table(nw.component.cast_state) do
        cast.spin_once(ecs_world, id, state)
    end
end

return animation