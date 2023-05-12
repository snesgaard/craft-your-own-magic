nw = require "nodeworks"
painter = require "painter"
constant = require "constant"
stack = nw.ecs.stack

-- System shortcuts
event = nw.system.event
input = nw.system.input
collision = nw.system.collision

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom

local function spin()
    while event.spin() > 0 do

    end
end

function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    collision.register("test", spatial(-10, -10, 20, 20))
end

function love.update(dt)
    event.emit("update", dt)
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
    input.keypressed(key)
end

function love.keyreleased(key)
    input.keyreleased(key)
end
