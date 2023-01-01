local ai = require "ai"

local function shoot_action(ctx, entity, target)
    local projectile_speed = 200
    local v = ai.vector_between(entity, target):normalize() * projectile_speed
    local x, y = entity:get(nw.component.position):unpack()
    nw.system.entity(ctx):spawn_from(entity, assemble.projectile, x, y, v.x, v.y)
    ai.wait(ctx, 1.0)
end

local function shoot_weight(distance_to_target, min_distance)
    return math.max(0, distance_to_target - min_distance) * 0.1
end

local function find_closest_other_team(entity)
    local other_team = entity:world()
        :get_component_table(nw.component.position)
        :keys()
        :map(function(id) return entity:world():entity(id) end)
        :filter(function(other) return not ai.same_team(entity, other) end)

    local distances =
        :map(function(other)
            return ai.distance_between(entity, other)
        end)

    local closest = distances:argsort():head()

    return other_team[closest], distances[closest]
end

local function random_weighted_pick(choices)
    local weight_sum = choices:reduce(function(sum, c2) return sum + c2.weight end, 0)
    if weight_sum == 0 or #choices == 0 then return end
    local roll = love.math.random() * weight_sum
    for _, c in ipairs(choices) do
        roll = roll - c.weight
        if roll <= 0 then return c.action end
    end

    return List.tail(choices).action
end

local function script(ctx, entity)
    local state = {
        patrol = entity:get(nw.component.patrol),
        task = nw.task(),
        patrol_speed = 100,
        min_distance = 200,
        action_pick_timer = nw.component.timer(1.0, 0)
    }

    local update = ctx:listen("update")
        :foreach(function(dt) state.action_pick_timer:update(dt) end)

    local closest_other = ctx:listen("moved")
        :filter(function(other) return not ai.same_team(entity, other) end)
        :map(function(other) return other, ai.distance_between(entity, other) end)
        :latest{find_closest_other_team(entity)}
        :reduce(function(state, other, distance)
            if not state or distance < state.distance then
                return {other = other, distance = distance}
            end

            return state
        end)

    local function patrol_action()
        return {
            action = {ai.action.patrol, ctx, entity, state.patrol, state.patrol_speed},
            weight = 1
        }
    end

    local function shoot_action()
        local other_distance = closest_other:peek()
        if not other_distance then return end

        return {
            action = {shoot_action, ctx, entity, other_distance.other},
            weight = shoot_weight(other_distance.distance, state.min_distance)
        }
    end

    local function decision(ctx, entity)
        if state.action_pick_timer:done() then
            local actions = list(
                patrol_action(),
                shoot_action()
            )

            local next_action = random_weighted_pick(actions)
            state.task = state.task:set(unpack(next_action.action))
            state.action_pick_timer:reset()
        end

        state.task:resume()
    end

    ctx:spin(decision)
end

local assemble = {}

function assemble.patrol_bot(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(50, 20)
        )
        :assemble(
            nw.system.script().set, script
        )
end

function assemble.projectile(entity, x, y, vx, vy)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(6, 6)
        )
        :set(nw.component.velocity, vx, vy)
        :set(nw.component.timer, 2.0)
        :set(nw.component.die_on_timer_complete)
end

return {
    assemble = assemble
}
