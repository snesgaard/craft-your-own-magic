nw = require "nodeworks"
input = require "system.input"
battle = require "system.battle"
painter = require "painter"

decorate(nw.component, require "component", true)
decorate(nw.drawable, require "drawable", true)

Frame.slice_to_pos = Spatial.centerbottom


function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    ecs_world = nw.ecs.entity.create()
    battle.setup(ecs_world)
end

function love.update(dt)
    battle.spin(ecs_world)
    nw.system.entity():emit(ecs_world, nw.component.update, dt)
    battle.spin(ecs_world)
end

function love.draw()
    painter.draw(ecs_world)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
    input.keypressed(ecs_world, key)
end

function love.mousepressed(x, y, button, isTouch)
    input.mousepressed(ecs_world, x, y, button, isTouch)
end

function love.mousereleased(x, y, button, isTouch)
    input.mousereleased(ecs_world, x, y, button, isTouch)
end

function love.mousemoved(x, y, dx, dy)
    input.mousemoved(ecs_world, x, y, dx, dy)
end
