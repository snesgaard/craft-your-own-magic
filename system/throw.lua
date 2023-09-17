local ai = require "system.ai"
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
            {nw.component.drawable, nw.drawable.bump_body},
            {nw.component.bouncy, 0.75},
            {nw.component.timer, 3.0},
            {nw.component.die_on_timer_done},
        },
        id
    )
    return id
end

function throw.deg2rad(deg) return deg * math.pi / 180 end

function throw.can_reach(id)

end

local function get_throw_slice_id(id)
    for _, slice_id in puppet_animator.view_current_slices(id) do
        if stack.get(nw.component.throw, slice_id) then return slice_id end
    end
end

local function get_throw_slice(id)
    local slice_id = get_throw_slice_id(id)
    if not slice_id then return end
    return collision.get_world_hitbox(slice_id)
end

local function get_future_throw_slice(id, animation)
    for _, _, slice, slice_data in puppet_animator.view_slices(id, animation) do
        if slice_data.throw then return slice end
    end
end

local function position_in_throw_frame(id, ox, oy, tx, ty)
    local t_o_id = tf.entity(id)
    local t_id_throw = transform(ox, oy)
    local t_o_target = transform(tx, ty)

    local t_o_throw = t_o_id * t_id_throw
    local t_throw_target = t_o_throw:inverse() * t_o_target

    return t_throw_target:transformPoint(0, 0)
end

local function execute_throw(node)
    if stack.get(nw.component.already_did_shoot, node) then return end
    -- Gather geometry
    local target = 1
    local x, y, w, h = get_throw_slice(node.id)
    local tx, ty, tw, th = collision.get_world_hitbox(target)

    if not tx or not x or not target then return end
    stack.set(nw.component.already_did_shoot, node)

    local t_o_throw = transform(x + w / 2, y + h / 2)
    local t_throw_o = t_o_throw:inverse()
    local t_o_target = transform(tx + tw / 2, ty + th / 2)
    local t_throw_target = t_throw_o * t_o_target

    local tx, ty = t_throw_target:transformPoint(0, 0)

    local speed = stack.ensure(nw.component.throw_speed, node.id)
    local angle = throw.solve_throw_angle_equation(tx, ty, speed, nw.component.gravity().y)

    if not angle then return end

    local vx, vy = throw.velocity(speed, angle)
    local cx, cy = t_o_throw:transformPoint(0, 0)
    throw.throw(cx, cy, vx, vy)
end

local function debug_draw(node)
    -- Gather geometry
    local slice = get_future_throw_slice(node.id, "throw")
    local target = 1
    local id = node.id
    local tx, ty, tw, th = collision.get_world_hitbox(target)

    -- Establish base transforms
    local t_o_target = transform(tx + tw / 2, ty + th / 2)
    local t_o_actor = tf.entity(node.id)
    local t_actor_throw = transform(slice:center():unpack())

    -- Establish link between throw and target
    local t_o_throw = t_o_actor * t_actor_throw
    local t_throw_o = t_o_throw:inverse()
    local t_throw_target = t_throw_o * t_o_target

    -- Compute target's relative position and solve the throw angle
    local tx, ty = t_throw_target:transformPoint(0, 0)
    local speed = stack.ensure(nw.component.throw_speed, node.id)
    local angle = throw.solve_throw_angle_equation(tx, ty, speed, nw.component.gravity().y)

    gfx.push()
    gfx.applyTransform(t_o_throw)
    gfx.circle("line", 0, 0, 4)

    if angle then
        throw.draw_trajectory(speed, angle, nw.component.gravity().y)
    end

    gfx.circle("line", tx, ty, 4)

    gfx.pop()
end

local function assembly_throw_projectile(node)
    local id = node.id
    if ai.flag(node, "init") then
        stack.set(nw.component.drawable, node, debug_draw)
        stack.set(nw.component.layer, node, 1000)
        puppet_animator.play(node.id, "throw")
    end

    execute_throw(node)

    if not puppet_animator.is_done(node.id) then return "pending" end

    stack.destroy(node)
    return "success"
end

local function ai_throw_projectile(id)
    return {
        id = id,
        type = "throw_projectile"
    }
end

ai.extend("throw_projectile", assembly_throw_projectile, ai_throw_projectile)

return throw