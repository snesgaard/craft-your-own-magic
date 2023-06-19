local motion = {}

-- TODO: Consider reimplementing this with a full lookup computation at the start of spin
function motion.should_skip(id)
    for status_id, should_skip in stack.view_table(nw.component.skip_motion) do
        local target = stack.ensure(nw.component.target, status_id)
        if target:argfind(id) and should_skip then return true end
    end
end

function motion.should_skip(id)
    return (stack.get(nw.component.skip_motion, id) or 0) > 0
end

function motion.spin_gravity(id, g, dt)
    if motion.should_skip(id) then return end

    local v = stack.ensure(nw.component.velocity, id)
    local next_v = v + g * dt
    stack.set(nw.component.velocity, id, next_v.x, next_v.y)
end

function motion.spin_velocity(id, v, dt)
    if motion.should_skip(id) then return end

    local p = stack.ensure(nw.component.position, id)
    local next_p = p + v * dt
    collision.move_to(id, next_p.x, next_p.y)
end

local function handle_collision(colinfo)
    local id = colinfo.item
    if colinfo.type == "slide" then
        local nx, ny = colinfo.normal.x, colinfo.normal.y
        local v = stack.get(nw.component.velocity, id) or vec2()
        if v and v.x * nx < 0 then v.x = 0 end
        if v and v.y * ny < 0 then v.y = 0 end

        if ny < 0 and v.y >= 0 then
            stack.set(nw.component.on_ground, id)
        end
    end
end

function motion.spin_move(cols)
    List.foreach(cols, handle_collision)
end

function motion.move_intent(dt)
    for id, intent in stack.view_table(nw.component.move_intent) do
        if stack.ensure(nw.component.disable_move, id) == 0 then
            local speed = stack.get(nw.component.move_speed, id) or 0
            collision.move(id, speed * dt * intent, 0)
        end
    end
end

function motion.flip_intent(dt)
    for id, intent in stack.view_table(nw.component.move_intent) do
        if stack.ensure(nw.component.disable_flip, id) == 0 then
            if intent < 0 then
                collision.flip_to(id, true)
            elseif  0 < intent then
                collision.flip_to(id, false)
            end
        end
    end
end

function motion.move_intent_from_flip(id, inverse)
    local m = stack.get(nw.component.mirror, id) and -1 or 1
    if inverse then m = -m end
    stack.set(nw.component.move_intent, id, m)
end

function motion.spin()
    for _, dt in event.view("update") do 
        for id, gravity in stack.view_table(nw.component.gravity) do
            motion.spin_gravity(id, gravity, dt)
        end

        for id, velocity in stack.view_table(nw.component.velocity) do
            motion.spin_velocity(id, velocity, dt)
        end

        motion.move_intent(dt)
        motion.flip_intent(dt)
    end

    for _, ax, ay, cols in event.view("move") do
        motion.spin_move(cols)
    end
end

function motion.jump_velocity_from_height(h, g)
    return math.sqrt(2 * h * g)
end

function motion.jump(id, h)
    local g = stack.ensure(nw.component.gravity, id)
    local v = motion.jump_velocity_from_height(h, g.y)
    stack.set(nw.component.velocity, id, 0, -v)
    event.emit("jump", id, stack.get(nw.component.position, id) or vec2())
end

function motion.is_on_ground(id)
    local on_ground = stack.get(nw.component.on_ground, id)
    if not on_ground then return false end
    return clock.get() - on_ground.time < on_ground.timeout
end

function motion.clear_on_ground(id)
    stack.remove(nw.component.on_ground, id)
end

function motion.restore(id)
    local m = stack.get(nw.component.restore_move, id) or 0
    if 0 < m then
        stack.remove(nw.component.restore_move, id)
        stack.map(nw.component.disable_move, id, add, -m)
    end

    local f = stack.get(nw.component.restore_flip, id) or 0
    if 0 < f then
        stack.remove(nw.component.restore_flip, id)
        stack.map(nw.component.disable_flip, id, add, -m)
    end
end

return motion