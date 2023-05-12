local motion = {}

function motion.spin_gravity(id, g, dt)
    local v = stack.ensure(nw.component.velocity, id)
    local next_v = v + g * dt
    stack.set(nw.component.velocity, id, next_v.x, next_v.y)
end

function motion.spin_velocity(id, v, dt)
    local p = stack.ensure(nw.component.position, id)
    local next_p = p + v * dt
    collision.move_to(id, next_p.x, next_p.y)
end

local function handle_collision(colinfo)
    if colinfo.type == "slide" then
        local nx, ny = colinfo.normal.x, colinfo.normal.y
        local v = stack.get(nw.component.velocity, colinfo.item.id)
        if v.x * nx < 0 then v.x = 0 end
        if v.y * ny < 0 then v.y = 0 end
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

return motion