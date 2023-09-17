nw = require "nodeworks"
painter = require "painter"
constant = require "constant"
stack = nw.ecs.stack

-- System shortcuts
event = nw.system.event
input = nw.system.input
collision = nw.system.collision
timer = nw.system.timer
camera = require "system.camera"
motion = require "system.motion"
clock = require "system.clock"
timer = require "system.timer"
tiled = require "tiled"
sfx = require "system.sfx"
gui = require "system.gui"
combat = require "system.combat"
rng = require "random"
tf = require "system.tf"
throw = require "system.throw"

ai = require "system.ai"
script = require "system.script"
puppet_control = require "system.puppet_control"
puppet_animator = require "system.puppet_animator"

function fixed(v) return function() return v end end

decorate(nw.component, require "component", true)
decorate(nw.drawable, require "drawable", true)

Frame.slice_to_pos = Spatial.centerbottom

function debug(id) return stack.get(nw.component.debug, id) end

function get_video(key, atlas_key)
    return Video.from_atlas(atlas_key or "art/characters", key)
end

function math.round(v)
    return math.floor(v + 0.5)
end

function real_random(min, max)
    return ease.linear(love.math.random(), min, max - min, 1)
end

transform = love.math.newTransform

local function spin()
    while event.spin() > 0 do
        clock.spin()
        motion.spin()
        timer.spin()
        sfx.spin()
        --- AI and actor control
        script.spin()
        puppet_control.spin()
        puppet_animator.spin()
        combat.spin()
        gui.spin()
        ---
        require("system.collision_resolver").spin()
    end
end

local function default_collision_filter(item, other)
    if stack.get(nw.component.is_ghost, item) or stack.get(nw.component.is_ghost, other) then
        return "cross"
    end

    if stack.get(nw.component.is_terrain, item) and stack.get(nw.component.is_terrain, other) then
        return 
    end

    if stack.get(nw.component.is_terrain, other) then
        if stack.get(nw.component.bouncy, item) then
            return "bounce"
        end
        return "slide"
    end

    return "cross"
end

function weak_assemble(arg, tag)
    local id = nw.ecs.id.weak(tag)
    stack.assemble(arg, id)
    return id
end

function choice(items, p)
    local p = p or {}
    local sum = 0

    for index, _ in ipairs(items) do
        sum = sum + (p[index] or 1)
    end

    if sum <= 0 then
        error("Weights was 0 or less")
    end

    local r = love.math.random()

    local w = 0
    for index, item in ipairs(items) do
        w = w + (p[index] or 1) / sum
        if r <= w then return item end
    end

    return List.tail(items)
end

function love.load(args)
    map = tiled.load("art/maps/build/bomber_develop.lua")

    local spawn = dict(tiled.object(map, "camera_spawn"))

    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    stack.set(nw.component.camera_tracking, constant.id.camera, 10)
    stack.set(nw.component.position, constant.id.camera, spawn.x, spawn.y)

    collision.set_default_filter(default_collision_filter)

    for index, name, slice, slice_data in puppet_animator.view_slices(2, "throw") do
        print(index.index, name)
    end
end

function love.update(dt)
    if not paused then event.emit("update", dt) end
    spin()

    -- HACK: Funky camera tracking!
    for id, _ in stack.view_table(nw.component.camera_should_track) do
        camera.track(id, constant.id.camera)
        break
    end
end

local throw_data = {
    x = 10,
    y = -20,
    speed = 300,
    angle = -math.pi * 0.25
}

function love.draw()
    painter.draw()

    gfx.push()
    painter.push_transform()
    if show_collision then collision.draw() end
    for id, _ in stack.view_table(nw.component.camera_should_track) do
        gfx.push()

        local t_o1 = tf.entity(id)
        local t_o2 = tf.entity(2)

        --local t_12 = t_o2 * t_o1:inverse()

        local t_os = t_o1 * transform(throw_data.x, throw_data.y)
        local tx, ty = tf.transform_origin(t_os:inverse() * t_o2)
        gfx.applyTransform(t_os)
        throw_data.angle = throw.solve_throw_angle_equation(
            tx, ty, throw_data.speed, nw.component.gravity().y
        )
        gfx.circle("line", 0, 0, 4)
        --gfx.circle("line", tx, ty, 4)
        if throw_data.angle then
            --throw.draw_trajectory(throw_data.speed, throw_data.angle, nw.component.gravity().y)
        end
        
        gfx.pop()
    end
    gfx.pop()
    
    gui.health_bar.draw()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "g" then collectgarbage() end
    if key == "c" then show_collision = not show_collision end
    if key == "p" then paused = not paused end
    if key == "t" then
        local t = tf.entity(1)
        local x, y = t:transformPoint(throw_data.x, throw_data.y)
        local vx, vy = tf.transform_velocity(
            t, throw.velocity(throw_data.speed, throw_data.angle)
        )
        throw.throw(x, y, vx, vy)
        
    end
    input.keypressed(key)
end

function love.keyreleased(key)
    input.keyreleased(key)
end
