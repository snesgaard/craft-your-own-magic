local JumpControl = require "script.jump_control"
local ball = require "system.ball"

local function x_dir()
    local neg = love.keyboard.isDown("left") and -1 or 0
    local pos = love.keyboard.isDown("right") and 1 or 0
    return neg + pos
end

local speed = 300

local function spawn_ball(entity)
    local bump_world = entity:get(nw.component.bump_world)
    local offset = vec2(50, -20)
    local pos = transform.position(entity, offset)
    local vel = transform.velocity(entity, vec2(200, 0))

    local ball_entity = entity:world():entity()
        :assemble(
            ball.assemble.projectile,
            pos.x, pos.y, "player", bump_world
        )
        :set(nw.component.velocity, vel.x, vel.y)
end


local function compute_jump_speed(entity)
    local gravity = entity:get(nw.component.gravity)
    if not gravity then return 0 end
    return JumpControl.speed_from_height(gravity.y, 50)
end

local function update_orientation(entity, x_dir)
    if x_dir < 0 then
        entity:set(nw.component.mirror, true)
    elseif 0 < x_dir then
        entity:set(nw.component.mirror, false)
    end
end

local dash_data = {
    distance = 200,
    time = 0.3
}

local function dash(ctx, entity)
    update_orientation(entity, x_dir())
    local sx = entity:get(nw.component.mirror) and -1 or 1

    local speed = 500
    local update = ctx:listen("update"):collect()

    entity
        :remove(nw.component.gravity)
        :remove(nw.component.velocity)
        :map(nw.component.invincible, function(v) return v + 1 end)

    local motion_tween = nw.component.tween(
        0, dash_data.distance, dash_data.time, ease.inOutQuad
    )
    while not motion_tween:is_done() and ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            local _, _, dv = motion_tween:update(dt)
            nw.system.collision(ctx):move(entity, dv * sx, 0)
        end
        ctx:yield()
    end

    entity
        :set(nw.component.gravity)
        :map(nw.component.invincible, function(v) return v - 1 end)
end

local function idle(ctx, entity)
    local update = ctx:listen("update"):collect()
    local jump = JumpControl.create(ctx, entity.id)
    local shoot = ctx:listen("keypressed")
        :filter(function(key) return key == "a" end)
        :latest()
    local do_dash = ctx:listen("keypressed")
        :filter(function(key) return key == "d" end)
        :latest()

    while ctx:is_alive() do
        for _, dt in ipairs(update:peek()) do
            nw.system.collision(ctx):move(entity, x_dir() * speed * dt, 0)
            update_orientation(entity, x_dir())
        end

        if jump:pop() then
            entity:map(nw.component.velocity, function(v)
                return vec2(v.x, -compute_jump_speed(entity))
            end)
        end

        if shoot:pop() then spawn_ball(entity) end
        if do_dash:pop() then return dash(ctx, entity) end

        ctx:yield()
    end
end

return function(ctx, entity)
    while ctx:is_alive() do idle(ctx, entity) end
end
