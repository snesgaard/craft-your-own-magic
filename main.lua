nw = require "nodeworks"

decorate(nw.component, require "component", true)

local collision_class = nw.system.collision():class()

function collision_class.is_solid(colinfo)
    return colinfo.type == "slide" or colinfo.type == "touch"
end

function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    world = nw.ecs.world()
    world:push(require "scene.player_control")
end

function love.update(dt)
    world:emit("update", dt):spin()
end

function love.draw()
    world:emit("draw"):spin()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
    world:emit("keypressed", key)
end

function love.mousemoved(x, y, dx, dy)
    world:emit("mousemoved", x, y, dx, dy)
end
