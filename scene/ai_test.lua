local script = nw.system.script()

local function move_to_point(ctx, entity, point, speed)
    local pos = entity:ensure(nw.component.position)
    local dpos = point - pos
    local dist = dpos:length()
    local duration =  dist / speed
    local time = 0

    local update = ctx:listen("update"):collect(false)

    ctx:spin(
        function(ctx)
            for _, dt in ipairs(update:peek()) do
                time = time + dt
            end
            if duration <= time then return true end

            local pos = ease.inOutQuad(time, pos, dpos, duration)
            nw.system.collision(ctx):move_to(entity, pos.x, pos.y)
        end
    )
end

local function patrol(ctx, entity)
    while ctx:is_alive() do
        move_to_point(ctx, entity, vec2(0, 0), 100)
        move_to_point(ctx, entity, vec2(200, 100), 100)
    end
end

local function decision(ctx, entity)
    local mousemoved = ctx:listen("mousemoved")
        :map(vec2)
        :latest(vec2(love.mouse.getPosition()))

    local distance_to_mouse = mousemoved
        :map(function(p)
            return (entity:ensure(nw.component.position) - p):length()
        end)

    local should_stop = distance_to_mouse
        :map(function(d) return d < 100 end)
        :latest()

    local patrol_co = coroutine.create(patrol)

    ctx:spin(function(ctx)
        if should_stop:peek() then return end
        local status, msg = coroutine.resume(patrol_co, ctx, entity)
        if not status then print(msg) end
    end)
end

local function draw_scene(ecs_world, bump_world)
    bump_debug.draw_world(bump_world)
end

return function(ctx)
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    local draw = ctx:listen("draw"):collect()

    local entity = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            100, 100, spatial(0, 0, 100, 100), bump_world
        )

    script.set(entity, decision)

    local ai_obs = script.observables(ctx)

    while ctx:is_alive() do
        script.handle_observables(ctx, ai_obs, ecs_world)

        draw:peek()
            :foreach(function()
                draw_scene(ecs_world, bump_world)
            end)
        ctx:yield()
    end
end
