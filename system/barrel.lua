local ai = require "ai"

local assemble = {}

function assemble.barrel(entity, x, y, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(10, 30), bump_world
        )
        :set(nw.component.is_effect)
        :set(nw.component.health, 1)
        :set(nw.component.event_on_death, function(entity)
            local pos = entity:ensure(nw.component.position)
            local bump_world = entity:get(nw.component.bump_world)
            return "barrel_explosion", {pos=pos, bump_world=bump_world}
        end)
end

function assemble.explosion(entity, x, y, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(100, 100), bump_world
        )
        :set(nw.component.timer, 0.5)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.is_effect)
        :set(
            nw.component.effect,
            {effect.damage, 100}
        )
        :set(nw.component.team, "neutral")
        :set(nw.component.trigger_once_pr_entity)
end

local rules = {}

function rules.barrel_explosion(ctx, args, ecs_world)
    ecs_world:entity()
        :assemble(assemble.explosion, args.pos.x, args.pos.y, args.bump_world)
end

return {
    assemble = assemble,
    rules = rules
}
