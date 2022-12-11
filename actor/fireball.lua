local ball = {}

function ball.spawn_explosion(ctx, item)
    local pos = item:ensure(nw.component.position)
    nw.system.entity(ctx):destroy(item)
    nw.system.entity(ctx):spawn_from(item, assemble.explosion, pos.x, pos.y)
end

function ball.on_collision(ctx, item, other, colinfo)
    if not nw.system.trigger(ctx):should(item, other) then return end

    local info = nw.system.combat(ctx):damage(other, 2)
    if info and info.damage > 0 then spawn_explosion(ctx, item) end
end

function ball.on_timer_complete(ctx, item) spawn_explosion(ctx, item) end

local explosion = {}

function explosion.on_collision(ctx, item, other, colinfo)
    if not nw.system.trigger(ctx):should(item, other) then return end

    nw.system.combat(ctx):damage(other, 10)
end

local assemble = {}

function assemble.fireball(entity, x, y, vx, vy)
    return entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(20, 20)
        )
        :set(nw.component.velocity, vx, vy)
        :set(nw.component.on_collision, on_collision)
        :set(nw.component.on_timer_complete, on_timer_complete)
        :set(nw.component.timer, 1.0)

end

function assemble.explosion(entity, x, y)
    return entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, spatial():expand(100, 100)
        )
        :set(nw.component.on_collision, explosion.on_collision)
        :set(nw.component.timer, 2.0)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.check_collision_once)
end

return assemble
