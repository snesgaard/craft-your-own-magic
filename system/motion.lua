local motion = {}

function motion.should_skip(id)
    local state = stack.get(nw.component.player_state, id)
    if not state then return end

    return state.name == "dash"
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
    local id = colinfo.item.id

    if colinfo.type == "slide" then
        local nx, ny = colinfo.normal.x, colinfo.normal.y
        local v = stack.get(nw.component.velocity, id)
        if v.x * nx < 0 then v.x = 0 end
        if v.y * ny < 0 then v.y = 0 end

        if ny < 0 then
            stack.set(nw.component.on_ground, id)
        end
    end
end

function motion.spin_move(cols)
    List.foreach(cols, handle_collision)
end

function motion.spin()
    for _, dt in event.view("update") do
        for id, gravity in stack.view_table(nw.component.gravity) do
            motion.spin_gravity(id, gravity, dt)
        end
        for id, velocity in stack.view_table(nw.component.velocity) do
            motion.spin_velocity(id, velocity, dt)
        end
    end

    for _, ax, ay, cols in event.view("move") do
        motion.spin_move(cols)
    end
end

function motion.is_on_ground(id)
    local on_ground = stack.get(nw.component.on_ground, id)
    if not on_ground then return false end
    return clock.get() - on_ground.time < on_ground.timeout
end

function motion.clear_on_ground(id)
    stack.remove(nw.component.on_ground, id)
end

return motion