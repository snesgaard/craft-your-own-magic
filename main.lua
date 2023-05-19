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

ai = require "system.ai"
script = require "system.script"
puppet_control = require "system.puppet_control"
puppet_animator = require "system.puppet_animator"

decorate(nw.component, require "component", true)
decorate(nw.drawable, require "drawable", true)

Frame.slice_to_pos = Spatial.centerbottom

local function spin()
    while event.spin() > 0 do
        clock.spin()
        motion.spin()
        timer.spin()
        --- AI and actor control
        script.spin()
        puppet_control.spin()
        puppet_animator.spin()
        ---
        require("system.collision_resolver").spin()
    end
end

local function default_collision_filter(item, other)
    if stack.get(nw.component.is_ghost, item) or stack.get(nw.component.is_ghost, other) then
        return "cross"
    end

    return "slide"
end

function weak_assemble(arg, tag)
    local id = nw.ecs.id.weak(tag)
    stack.assemble(arg, id)
    return id
end

function love.load(args)
    map = tiled.load("art/maps/build/test.lua")

    local spawn = dict(tiled.object(map, "camera_spawn"))

    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    stack.set(nw.component.camera_tracking, constant.id.camera, 10)
    stack.set(nw.component.position, constant.id.camera, spawn.x, spawn.y)

    collision.set_default_filter(default_collision_filter)

    stack.assemble(
        {
            {nw.component.is_ghost},
            {nw.component.drawable, nw.drawable.bump_body},
            {nw.component.layer, 1000}
        },  
        "aiboi"
    )
    collision.register("aiboi", spatial(0, 0, 10, 10))
    collision.warp_to("aiboi", 0, -100)
end

function love.update(dt)
    event.emit("update", dt)
    spin()

    -- HACK: Funky camera tracking!
    for id, _ in stack.view_table(nw.component.camera_should_track) do
        camera.track(id, constant.id.camera)
        break
    end
end

function love.draw()
    painter.draw()

    gfx.push()
    painter.push_transform()
    if show_collision then collision.draw() end
    gfx.pop()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "g" then collectgarbage() end
    if key == "c" then show_collision = not show_collision end
    input.keypressed(key)
end

function love.keyreleased(key)
    input.keyreleased(key)
end
