local throw = {}

function throw.trajectory_point(speed, angle, gravity, time)
    local x = speed * time * math.cos(angle)
    local y = speed * time * math.sin(angle) + 0.5 * gravity * time * time
    return x, y
end

function throw.draw_trajectory(speed, angle, gravity, time, step)
    local time = time or 1
    local step = step or 0.1
    local line = {}
    local t = 0

    while t < time do
        local x, y = throw.trajectory_point(speed, angle, gravity, t)
        table.insert(line, x)
        table.insert(line, y)
        t = t + step
    end

    gfx.line(line)
end

function throw.velocity(speed, angle)
    return math.cos(angle) * speed, math.sin(angle) * speed
end

function throw.solve_throw_angle_equation(x, y, v, g)
    local g = -g
    local r_square = math.pow(v, 4) - g * (g * math.pow(x, 2) + 2 * y * math.pow(v, 2))
    if r_square < 0 then return end

    local r = math.sqrt(r_square)
    local a1 = (math.pow(v, 2) + r) / (g * x)
    local a2 = (math.pow(v, 2) - r) / (g * x)
    local v1, v2 = math.atan(a1), math.atan(a2)
    if x > 0 then 
        return v1, v2
    else
        return v1 + math.pi, v2 + math.pi
    end
end

function throw.throw(x, y, vx, vy)
    local id = nw.ecs.id.strong("throw")
    
    collision.register(id, spatial():expand(10, 10))
    collision.warp_to(id, x, y)

    stack.assemble(
        {
            {nw.component.velocity, vx, vy},
            {nw.component.gravity},
            {nw.component.drawable, nw.drawable.bump_body}
        },
        id
    )
    return id
end

function throw.deg2rad(deg) return deg * math.pi / 180 end

return throw