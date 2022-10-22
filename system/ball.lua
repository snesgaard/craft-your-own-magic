local component = {}

function component.ball_projectile() return true end

function component.ball_explosion() return true end

local assemble = {}

function assemble.ball_projectile(entity, x, y, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(10, 10), bump_world
        )
        :set(component.ball_projectile)
        :set(nw.component.timer, 2.0)
        --:set(nw.component.die_on_timer_complete)
end

function assemble.ball_explosion(entity, x, y, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(100, 100), bump_world
        )
        :set(nw.component.timer, 2.0)
        :set(nw.component.die_on_timer_complete)
end

local rules = {}

function rules.spawn_explosion(ctx, ecs_world, x, y, bump_world)
    local entity = ecs_world:entity()
        :assemble(assemble.ball_explosion, x, y, bump_world)
    ctx:emit("on_explosion_spawned", entity)
end

function rules.trigger_explosion(ctx, entity)
    if not entity:has(component.ball_projectile) then return end
    if entity:has(nw.component.expired) then return end

    local x, y = entity:ensure(nw.component.position):unpack()
    local bump_world = entity:get(nw.component.bump_world)

    entity:set(nw.component.expired)
    ctx:emit("destroy", entity.id)
    return rules.spawn_explosion(ctx, entity:world(), x, y, bump_world)
end

local function handle_collision(ctx, item, other)
    return rules.trigger_explosion(ctx, item)
end

function rules.collision(ctx, colinfo)
    local item = colinfo.ecs_world:entity(colinfo.item)
    local other = colinfo.ecs_world:entity(colinfo.other)
    handle_collision(ctx, item, other)
    handle_collision(ctx, other, item)
end

function rules.timer_completed(ctx, id, ecs_world)
    return rules.trigger_explosion(ctx, ecs_world:entity(id))
end

local system = {}

system.rules = rules

system.assemble = assemble

return system
