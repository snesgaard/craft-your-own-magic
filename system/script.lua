local patrol_box = {}

function patrol_box.move_to(_, id, goal)
    for _, dt in event.view("update") do
        local pos = stack.ensure(nw.component.position, id)
        local dir = goal - pos
        local l = dir:length()
        local speed = 50
        local step = speed * dt

        if l <= step then
            collision.move_to(id, goal.x, goal.y)
            return "success"
        else
            collision.move(id, step * dir.x / l, step * dir.y / l)
        end
    end

    return "pending"
end

function patrol_box.spin_once(id, args)
    local task = {
        ai.sequence_forget,
            {patrol_box.move_to, id, vec2(-100, -100)},
            {patrol_box.move_to, id, vec2(0, -100)}
    }

    ai.run(args, task)
end

function patrol_box.spin()
    for id, args in stack.view_table(nw.component.script("patrolbox")) do
        patrol_box.spin_once(id, args)
    end
end

local player_boxer = {}

function player_boxer.spin_once(id)
    for _, key in event.view("keypressed") do
        if key == "space" then
            stack.set(nw.component.jump_intent, id)
        elseif key == "a" then
            stack.set(nw.component.punch_intent, id, true)
        elseif key == "d" then
            stack.set(nw.component.dash_intent, id)
        elseif key == "s" then
            stack.set(nw.component.attack_intent, id)
        end
    end

    for _, key in event.view("keyreleased") do
        if key == "a" then
            stack.set(nw.component.punch_intent, id, false)
        end
    end 

    for _, dt in event.view("update") do
        stack.set(nw.component.move_intent, id, input.get_direction_x())
    end
end

function player_boxer.spin()
    for id, _ in stack.view_table(nw.component.script("boxer-player")) do
        player_boxer.spin_once(id)
    end 
end

local player = {}

function player.spin_once(id)
    for _, key in event.view("keypressed") do
        if key == "space" then
            stack.set(nw.component.jump_intent, id)
        elseif key == "d" then
            stack.set(nw.component.dash_intent, id)
        elseif key == "a" then
            stack.set(nw.component.attack_intent, id)
        elseif key == "s" then
            stack.set(nw.component.hitstun_intent, id)
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
    player_boxer.spin()
    patrol_box.spin()
end

return script 