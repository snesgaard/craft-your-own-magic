local impact = {}

impact.image = gfx.prerender(4, 1, function(w, h)
    return gfx.ellipse("fill", w / 2, h / 2, w / 2, h / 2)
end)

function impact.particle_args(x, y, w, h)
    return {
        image = impact.image,
        buffer = 20,
        pos = {x + w / 2, y + h},
        area = {"uniform", w / 2, 4},
        emit = 20,
        lifetime = {0.5, 0.75},
        dir = -math.pi / 2,
        speed = {100, 200},
        spread = math.pi,
        acceleration = {0, 200},
        damp = 1,
        color = {
            color(0.2, 0.4, 0.9, 1),
            color(0.8, 0.7, 0.2, 1),
            color(0.8, 0.2, 0.2, 1),
            color(0.2, 0.2, 0.2, 0),
        },
        relative_rotation = true
    }
end

function impact.trigger(id, args)
    if stack.get(nw.component.sfx_triggered, id) then return end
    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then return end

    stack.assemble(
        {
            {nw.component.particles, impact.particle_args(x, y, w, h)},
            {nw.component.drawable, nw.drawable.particles},
            {nw.component.die_on_empty},
            {nw.component.layer, 1000}
        },
        nw.ecs.id.strong("sfx/impact")
    )

    stack.ensure(nw.component.sfx_triggered, id)
end

function impact.update(dt)
    for id, args in stack.view_table(nw.component.sfx("impact")) do
        impact.trigger(id, args)
    end
end

local sparks = {}

function sparks.direction(mirror)
    return -math.pi * 0.5
end

sparks.particle_args = {
    buffer = 20,
    image = gfx.prerender(4, 1, function(w, h)
        gfx.ellipse("fill", w / 2, h / 2, w / 2, h / 2)
    end),
    dir = -math.pi * 3 / 4,
    acceleration = {0, 30},
    speed = {50, 70},
    spread = math.pi * 0.75,
    rate = 14,
    lifetime = 0.5,
    damp = 1,
    relative_rotation = true,
    color = {
        color(0.2, 0.7, 0.7, 1),
        color(0.8, 0.7, 0.2, 1),
        color(0.8, 0.2, 0.2, 1),
        color(0.2, 0.2, 0.2, 0),
    }
}

function sparks.ensure_components(id)
    stack.ensure(nw.component.particles, id, sparks.particle_args)
    stack.ensure(nw.component.drawable, id, nw.drawable.particles)
    stack.ensure(nw.component.layer, id, 1000)
end

function sparks.particle_properties(id)
    local p = stack.get(nw.component.particles, id)
    if not p then return end

    local mirror = stack.get(nw.component.mirror, id)

    p:setDirection(sparks.direction(mirror))

    local x = collision.get_world_hitbox(id)
    if x then
        p:start()
    else
        p:stop()
    end
end

function sparks.move_to_collider(id)
    local x, y, w, h = collision.get_world_hitbox(id)
    local p = stack.get(nw.component.particles, id)
    if not x or not p then return end
    local cx = x + w / 2
    local cy = y + h
    local dx = w / 2
    local dy = 1
    p:setEmissionArea("uniform", dx, dy, 0, false)
    p:setPosition(cx, cy - 2)
end

function sparks.update(dt)
    for id, args in stack.view_table(nw.component.sfx("sparks")) do
        sparks.ensure_components(id, args)
        sparks.particle_properties(id)
        sparks.move_to_collider(id, args)
    end
end

local jump = {}

function jump.drawable(id)
    local t, d = timer.get(id)
    if not t then return end

    gfx.push("all")

    nw.drawable.push_transform(id)

    local r = ease.linear(t, 0, 50, d)
    local alpha = ease.inQuad(t, 1, -1, d)
    gfx.setColor(1, 1, 1, alpha)
    gfx.rectangle("fill", spatial():expand(r, 5):unpack())

    gfx.pop()
end

function jump.spawn(x, y)
    return stack.assemble(
        {
            {nw.component.position, x, y},
            {nw.component.drawable, jump.drawable},
            {nw.component.timer, 0.2},
            {nw.component.die_on_timer_done},
            {nw.component.layer, 1000}
        },
        nw.ecs.id.strong("jumpsfx")
    )
end

local particles = {}

function particles.update(dt)
    for _, p in stack.view_table(nw.component.particles) do
        p:update(dt)
    end

    for id, p in stack.view_table(nw.component.particles) do
        if stack.get(nw.component.die_on_empty, id) and p:getCount() == 0 then
            stack.destroy(id)
        end
    end
end

local sfx = {}

function sfx.spin()
    for _, id, pos in event.view("jump") do
        jump.spawn(pos.x, pos.y)
    end

    for _, dt in event.view("update") do
        sparks.update(dt)
        impact.update(dt)
        particles.update(dt)
    end
end

return sfx