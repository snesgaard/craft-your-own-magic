local assemble = {}

assemble.CONFIG = {
    DURATION = 0.5,
    DAMAGE = 5
}

local barrel = {}

function barrel.on_death(ctx, entity)
    local pos = item:ensure(nw.component.position)
    nw.system.entity(ctx):spawn_from(entity)
        :assemble(assemble.explosion, pos.x , pos.y)
end

local explosion = {}

function explosion.on_collision(ctx, item, other, colinfo)
    if not nw.system.trigger(ctx):should(item, other) then return end
    nw.system.combat(ctx):damage(other, assemble.CONFIG.DAMAGE)
end

function assemble.barrel(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(10, 20)
        )
        :set(nw.component.brittle)
        :set(nw.component.on_death, barrel.on_death)
end

function assemble.explosion(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, spatial():expand(100, 100)
        )
        :set(nw.component.timer, assemble.CONFIG.DURATION)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.on_death, barrel.on_death)
        :set(nw.component.on_collision, explosion.on_collision)
end
