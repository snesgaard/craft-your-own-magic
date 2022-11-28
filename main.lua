nw = require "nodeworks"
effect = require "effect"
animation = require "system.animation"

function declare_world_interface(class)
    local default_instance = class()

    return function(ctx)
        if not ctx then return default_instance end
        local world = ctx.world or ctx
        world[class] = world[class] or class(world)
        return world[class]
    end
end

decorate(nw.component, require "component", true)

local collision_class = nw.system.collision():class()
local system = require "system"

transform = require "transform"

function collision_class.is_solid(colinfo)
    return colinfo.type == "slide" or colinfo.type == "touch" or colinfo.type == "bounce"
end

collision_class.default_filter = system.collision.collision_filter

function mirror_call(func, item, other, ...)
    return func(item, other, ...) or func(other, item, ...)
end

Frame.slice_to_pos = Spatial.centerbottom

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
    world:emit("keypressed", key):spin()
end

function love.mousemoved(x, y, dx, dy)
    world:emit("mousemoved", x, y, dx, dy):spin()
end
