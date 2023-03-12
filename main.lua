nw = require "nodeworks"
input = require "system.input"
battle = require "system.battle"
painter = require "painter"
event = require "event"

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

    gfx.push("all")
    if battle.is_battle_over(ecs_world) then
        local w, h = gfx.getWidth(), gfx.getHeight()
        local shape = spatial(w / 2, h / 2):expand(300, 100)
        gfx.setColor(1, 1, 1)
        gfx.rectangle("fill", shape:unpack())
        gfx.setColor(0, 0, 0)
        local player_win = battle.is_team_alive(ecs_world, nw.component.player_team)
        local text = player_win and "WIN :D" or "DEFEAT :("
        nw.drawable.draw_text(text, shape, "center", "center")
    end
    gfx.pop()
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
