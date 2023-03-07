nw = require "nodeworks"
input = require "system.input"
mouse = require "system.mouse"
button = require "system.button"
slider = require "system.slider"
painter = require "painter"

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom


function love.load(args)
    if args[1] == "test" then
        require "test"
        return love.event.quit()
    end

    ecs_world = nw.ecs.entity.create()

    ecs_world:entity("button")
        :set(nw.component.hitbox, 100, 100, 100, 100)
        :set(nw.component.mouse_rect, 100, 100, 100, 100)
        :set(nw.component.drawable, nw.drawable.body)

    ecs_world:entity("slider")
        :set(nw.component.mouse_rect, 100, 300, 100, 20)
        :set(nw.component.drawable, slider.draw_widget)
        :set(nw.component.slider, 50, 0, 100)
end

local function color_is_down(entity)
    if entity:get(nw.component.is_down) then
        entity:set(nw.component.color, 1, 0, 0)
    else
        entity:remove(nw.component.color)
    end
end

local function handle_gui_logic(ecs_world)
    if ecs_world:get(nw.component.pressed, "button") then
        print("sonic boom!")
    end

    color_is_down(ecs_world:entity("button"))
    color_is_down(ecs_world:entity("slider"))
end

function love.update(dt)
    nw.system.entity():emit(ecs_world, nw.component.update, dt)

    while nw.system.entity():spin(ecs_world) > 0 do
        mouse.spin(ecs_world)
        button.spin(ecs_world)
        slider.spin(ecs_world)
    end
    
    handle_gui_logic(ecs_world)
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
