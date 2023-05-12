nw = require "nodeworks"
painter = require "painter"
constant = require "constant"
stack = nw.ecs.stack

-- System shortcuts
event = nw.system.event
input = nw.system.input
collision = nw.system.collision
camera = require "system.camera"
motion = require "system.motion"

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom

local function spin()
    while event.spin() > 0 do
        motion.spin()
    end
end

local function default_collision_filter(item, other)
    return "slide"
end

function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    stack.assemble(
        {
            {nw.component.gravity, 0, 100}
        },
        "test"
    )


    collision.register("test", spatial(-10, -10, 20, 20))


    collision.register("test2", spatial():move(0, 30):expand(1000, 10))
    collision.register("test3", spatial():move(0, -40):expand(1000, 10))

    stack.set(nw.component.camera_tracking, constant.id.camera, 20)

    collision.set_default_filter(default_collision_filter)
end

function love.update(dt)
    event.emit("update", dt)
    camera.track("test")
    spin()
end

function love.draw()
    painter.draw()

    gfx.push()
    painter.push_transform()
    collision.draw()
    gfx.pop()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "right" then collision.move("test", 10, 0) end
    if key == "left" then collision.move("test", -10, 0) end
    if key == "up" then collision.move("test", 0, -20) end
    if key == "down" then collision.move("test", 0, 10) end
    input.keypressed(key)
end

function love.keyreleased(key)
    input.keyreleased(key)
end
