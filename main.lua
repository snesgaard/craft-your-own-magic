nw = require "nodeworks"
animation = require "system.animation"

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom

function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    world = nw.ecs.world()
    world:push(require "scene.player")
end

function love.update(dt)
    world:emit("update", dt):spin()
end

function love.draw()
    world:emit("draw"):spin()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
    world:emit("keypressed", key):spin()
end

function love.mousemoved(x, y, dx, dy)
    world:emit("mousemoved", x, y, dx, dy):spin()
end
