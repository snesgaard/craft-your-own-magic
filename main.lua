nw = require "nodeworks"

decorate(nw.component, require "component", true)

local collision_class = nw.system.collision():class()

transform = require "transform"

function collision_class.is_solid(colinfo)
    return colinfo.type == "slide" or colinfo.type == "touch"
end

local function check_slide(item, other)
    local c = nw.component
    return (item:has(c.is_actor) and other:has(c.is_terrain))
        or (item:has(c.is_terrain) and other:has(c.is_terrain))
end

function collision_class.default_filter(ecs_world, item, other)
    local item = ecs_world:entity(item)
    local other = ecs_world:entity(other)
    if mirror_call(check_slide, item, other) then return "slide" end
    return "cross"
end

function mirror_call(func, item, other, ...)
    return func(item, other, ...) or func(other, item, ...)
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
