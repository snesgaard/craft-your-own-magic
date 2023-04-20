local bouncing_flask = {}

function bouncing_flask.spin(ecs_world)
    local state_table = ecs_world:get_component_table(nw.component.bouncing_flask_state)
    for id, state in pairs(state_table) do
        bouncing_flask.spin_state(ecs_world, id, state)
    end
end

function bouncing_flask.spin_state(ecs_world, id, state)
    if bouncing_flask.is_done(ecs_world, id, state) then
        ecs_world:set(nw.component.hidden, id)
        return
    end
    if bouncing_flask.is_bounce_over(ecs_world, id, state) then
        bouncing_flask.do_bounce(ecs_world, id, state)
    end
    bouncing_flask.compute_position(ecs_world, id, state)
end

function bouncing_flask.is_bounce_over(ecs_world, id)
    local timer = ecs_world:get(nw.component.timer, id)
    return not timer or timer:done()
end

function bouncing_flask.is_done(ecs_world, id, state)
    local state = state or ecs_world:get(nw.component.bouncing_flask_state, id)
    return not state or state.count < 0
end

function bouncing_flask.compute_position_init(ecs_world, id, state)
    if state.target then
        return ecs_world:get(nw.component.position, id)
    elseif state.user then
        return animation.compute_cast_hitbox(ecs_world, state.user):center()
    else
        return vec2()
    end
end

function bouncing_flask.compute_position_end(ecs_world, id, state)
    if not state.target then vec2(0, 0) end
    return animation.compute_body_hitbox(ecs_world, state.target):centertop()
end

function bouncing_flask.do_bounce(ecs_world, id, state)
    if state.target then
        -- Activate effect
        local effects = ecs_world:ensure(nw.component.effect, id)
        for index, effect in ipairs(effects) do
            combat.core.resolve_single(ecs_world, state.user, state.target, effect)
        end
    end
    -- Reset animation
    local prev_target = state.target or state.user
    local prev_position = bouncing_flask.compute_position_init(ecs_world, id, state)
    local timer = ecs_world:ensure(nw.component.timer, id, 0.5)
    timer:reset()

    local next_target = state.potential_targets
        :filter(function(id) return combat.core.is_alive(ecs_world, id) end)
        :shuffle()
        :head()
    
    if not next_target then
        state.count = -1
    else
        state.target = next_target
        state.pos_init = prev_position
        state.pos_end = bouncing_flask.compute_position_end(ecs_world, id, state)
        state.count = state.count - 1
    end
end

function bouncing_flask.compute_position(ecs_world, id, state)
    local timer = ecs_world:get(nw.component.timer, id)
    if not timer then return end
    local t = timer:inverse_normalized()
    local pos = animation.ballistic_curve(t, state.pos_init, state.pos_end)
    ecs_world:set(nw.component.position, id, pos.x, pos.y)
end

local dagger_sprite = {}

function dagger_spray.spin(ecs_world)
    for id, state in pairs(ecs_world:get_component_table(nw.component.dagger_spray_state)) do
        dagger_spray.spin_once(ecs_world, id, state)
    end
end

function dagger_spray.spin_once(ecs_world, id, state)
    if dagger_spray.is_done(ecs_world, id, state) then
        dagger_spray.trigger_effect(ecs_world, id, state)
    end
end

function dagger_spray.trigger_effect(ecs_world, id, state)
    local data = ecs_world:entity(id)
    if not flag(data, "resolve") then return end
    
    local effects = ecs_world:ensure(nw.component.effect, id)
    for _, effect in ipairs(effects) do
        combat.core.resolve(ecs_world, state.user, state.target, effect)
    end
end

function dagger_spray.is_done(ecs_world, id)
    local timer = ecs_world:get(nw.component.timer, id)
    if not timer then return true end
    return timer:done()
end

local animation = {
    bouncing_flask = bouncing_flask
}

function animation.spin(ecs_world)
    local systems = list(
        bouncing_flask,
        dagger_spray
    )

    for _, sys in ipairs(systems) do sys.spin(ecs_world) end
end

return animation