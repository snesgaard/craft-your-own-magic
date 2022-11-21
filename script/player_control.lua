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

local hitbox_animation = animation.animation()
    :timeline(
        "attack",
        list(
            {value=nil, time=-math.huge},
            {value=spatial(0, 0, 20, 20), time=0},
            {value=nil, time=0.5}
        )
    )



local function attack(ctx, entity)
    entity:remove(nw.component.velocity)

    local pos = entity:ensure(nw.component.position)
    local bump_world = entity:get(nw.component.bump_world)
    local mirror = entity:ensure(nw.component.mirror)

    local timer = nw.component.timer(1.0)
    local hb_entity = entity:world():entity()
        :set(nw.component.position, pos.x, pos.y)
        :set(nw.component.mirror, mirror)


    local player = animation.player(hitbox_animation)
        :on_update(function(value, prev_value)
            if value.attack ~= prev_value.attack then
                hb_entity:assemble(nw.system.collision().assemble.set_bump_world)
                if value.attack ~= nil then
                    hb_entity
                        :set(nw.component.hitbox, value.attack:unpack())
                        :assemble(
                            nw.system.collision().assemble.set_bump_world,
                            bump_world
                        )
                end
            end
        end)
        :play_once()
        :spin(ctx)

    hb_entity:destroy()
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
    local do_attack = ctx:listen("keypressed")
        :filter(function(key) return key == "s" end)
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
        if do_attack:pop() then return attack(ctx, entity) end

        ctx:yield()
    end
end

return function(ctx, entity)
    while ctx:is_alive() do idle(ctx, entity) end
end
