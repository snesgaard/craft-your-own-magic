local transform = require "system.transform"
local animation_util = require "animation_util"
local combat = require "combat"

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
        return animation_util.compute_cast_hitbox(ecs_world, state.user):center()
    else
        return vec2()
    end
end

function bouncing_flask.compute_position_end(ecs_world, id, state)
    if not state.target then vec2(0, 0) end
    return animation_util.compute_body_hitbox(ecs_world, state.target):centertop()
end

function bouncing_flask.do_bounce(ecs_world, id, state)
    if state.target then
        -- Activate effect
        local effects = ecs_world:ensure(nw.component.effect, id)
        for index, effect in ipairs(effects) do
            combat.core.resolve_single(ecs_world, state.user, state.target, effect)
        end
    end
    -- Reset animation_util
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
    local pos = animation_util.ballistic_curve(t, state.pos_init, state.pos_end)
    ecs_world:set(nw.component.position, id, pos.x, pos.y)
end

return bouncing_flask