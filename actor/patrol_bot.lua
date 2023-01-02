local ai = require "ai"

local component = {}

function component.attack_cooldown(cooldown) return cooldown end

local assemble = {}

function assemble.attack_cooldown(entity)
    return nw.system.timer().named_timer(entity, component.attack_cooldown, 2)
end

local action = {}

function action.attack(ctx, entity, target_pos)
    entity:assemble(assemble.attack_cooldown)
end

local score = {}

function score.attack(item, other, distance_to_other, min_distance)
    local timer = nw.system.timer()

    local timer_score = timer.is_done(entity, component.attack_cooldown) and 0 or 1
    local distance_score = (min_distance - distance_to_other) / min_distance
    return distance_score * timer_score
end

local decision = {}

function decision.patrol(entity)
    local patrol_route = entity:get(nw.component.patrol)
    return {
        score = 0.01,
        func = action.patrol,
        args = {entity, patrol_route, 100, 0.5}
    }
end

function decision.attack(entity)
    local min_distance = 200
    local foes = nw.system.collision():query_around_entity(entity, min_distance)
        :filter(function(other) return not ai.same_team(entity, other) end)

    local distances = foes
        :map(function(other) return ai.distance_between(entity, other) end)

    local arg_closest = distances:argsort():head()

    if not arg_closest then return end

    local other = foes[arg_closest]
    local distance = distances[arg_closest]

    local other_pos = other:get(nw.component.position)

    return {
        score = score.attack(entity, other, distance, min_distance),
        func = action.attack,
        args = {entity, other}
    }
end


function assemble.patrol_bot(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(50, 20)
        )
        :assemble(
            nw.system.script().set, script
        )
        :set(nw.component.decision, decisions)
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
