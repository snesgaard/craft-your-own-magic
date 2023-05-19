local player = {}

function player.spin_once(id)
    for _, key in event.view("keypressed") do
        if key == "space" then
            stack.set(nw.component.jump_intent, id)
        elseif key == "d" then
            stack.set(nw.component.dash_intent, id)
        elseif key == "a" then
            stack.set(nw.component.attack_intent, id)
        end
    end

    for _, dt in event.view("update") do
        stack.set(nw.component.move_intent, id, input.get_direction_x())
    end
end

function player.spin()
    for id, _ in stack.view_table(nw.component.script("player")) do
        player.spin_once(id)
    end
end

local script = {}

function script.spin()
    player.spin()
end

return script 