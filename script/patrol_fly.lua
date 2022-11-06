local ai = require "ai"

local function roll(l)
    return l:body() + list(l:head())
end

local function do_patrol(ctx, entity, patrol, speed, dt)
    local target = patrol:head()
    local next_pos, is_done = ai().move_to(entity, target, speed * dt)
    nw.system.collision(ctx):move_to(entity, next_pos.x, next_pos.y)
    return is_done and roll(patrol) or patrol
end

local function should_shoot(entity)
    local player = entity:world():entity("player")
    local l = player:ensure(nw.component.position) - entity:ensure(nw.component.position)
    return l:length() < 150
end

local function shoot(entity, target_pos)
    local pos = entity:ensure(nw.component.position)
    local bump_world = entity:get(nw.component.bump_world)
    local velocity = 200 * (target_pos - pos):normalize()

    return entity:world():entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            pos.x, pos.y, nw.component.hitbox(10, 10), bump_world
        )
        :set(nw.component.is_effect)
        :set(nw.component.timer, 2.0)
        :set(nw.component.velocity, velocity.x, velocity.y)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.ignore_terrain)
        :set(
            nw.component.effect,
            {effect.damage, 2}
        )
        :set(nw.component.trigger_once_pr_entity)
        :set(nw.component.team, "enemy")
        :set(nw.component.event_on_effect_trigger, function(source)
            return "destroy", source.id
        end)
end

local function shoot_at_player(entity)
    local player = entity:world():entity("player")
    local player_pos = player:get(nw.component.position)
    return shoot(entity, player_pos)
end

return function(ctx, entity)
    local patrol = list(
        vec2(300, 0),
        vec2(300, 300)
    )

    local update = ctx:listen("update"):collect()
    local speed = 200
    local shoot_cooldown = nw.component.timer(2.5):finish()

    while ctx:is_alive() do
        for _,  dt in ipairs(update:pop()) do
            patrol = do_patrol(ctx, entity, patrol, speed, dt)
            shoot_cooldown:update(dt)
        end

        if should_shoot(entity) and shoot_cooldown:done() then
            shoot_cooldown:reset()
            shoot_at_player(entity)
        end

        ctx:yield()
    end
end
