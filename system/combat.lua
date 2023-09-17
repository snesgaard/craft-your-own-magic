local combat = {}

function combat.damage(target, damage)
    if stack.ensure(nw.component.immune("damage"), target) > 0 then return end

    local hp = stack.get(nw.component.health, target)
    if not hp or hp.value <= 0 then return end

    local real_damage = math.min(damage, hp.max)
    local next_hp = hp.value - real_damage

    local info = {
        damage = real_damage,
        target = target
    }

    event.emit("damage", info)
    stack.set(nw.component.health, target, next_hp, hp.max)
    return info
end

function combat.knockback(target, knockback)
    if not stack.ensure(nw.component.health, target) then
        if not stack.ensure(nw.component.immune("knockback"), target, 1) > 0 then
            return
        end
    elseif stack.ensure(nw.component.immune("knockback"), target) > 0 then
        return
    elseif stack.ensure(nw.component.immune("damage"), target) > 0 then
        return
    end

    collision.move(target, knockback, 0)
end

function combat.stun(target)
    if stack.ensure(nw.component.immune("stun"), target) > 0 then return end

    stack.set(nw.component.reset_script, target)
    stack.set(nw.component.is_stunned, target, 1.0)
end

function combat.is_stunned(target)
    local is_stunned = stack.get(nw.component.is_stunned, target)
    if not is_stunned then return false end

    return not timer.is_done(is_stunned)
end

function combat.restore(target)
    local stats = {"damage"}
    for _, key in ipairs(stats) do
        local d = stack.get(nw.component.restore_immune(key), target) or 0
        if d > 0 then
            stack.remove(nw.component.restore_immune(key), target)
            stack.map(nw.component.immune(key), target, add, -d)
        end
    end
end

function combat.is_dead(id)
    local health = stack.get(nw.component.health, id)
    if not health then return false end

    return health.value <= 0
end

local shooting = {}

function shooting.handle_shoot(id, projectile_type)
    if stack.get(nw.component.already_did_shoot, id) then return end

    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then return end
    
    local pid = nw.ecs.id.strong("bullet")
    collision.register(pid, spatial():expand(10, 10))
    collision.warp_to(pid, x + w / 2, y + h / 2)

    local mirror = stack.get(nw.component.mirror, id)
    local sx = mirror and -1 or 1

    
    stack.assemble(
        {
            {nw.component.is_ghost},
            {nw.component.velocity, sx * 100, 0},
            {nw.component.drawable, nw.drawable.bump_body},
            {nw.component.timer, 2.0},
            {nw.component.die_on_timer_done},
            {nw.component.damage, 1},
        },
        pid
    )

    if stack.get(nw.component.player_controlled, id) then
        stack.set(nw.component.player_controlled, pid)
    end
    
    collision.flip_to(pid, mirror)
    stack.set(nw.component.already_did_shoot, id)
end

local throw = {}

function throw.get_center(id)
    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then return end
    return x + w / 2, y + h / 2
end

function throw.hitbox_from_type(throw_type)
    return spatial():expand(10, 10)
end

function throw.assemble_from_type(throw_type)
    return {
        {nw.component.timer, 2.0}
    }
end

function throw.velocity_from_target(id)

end

function throw.velocity_from_settings(id)
    local m = stack.get(nw.component.mirror, id)
    local sx = m and -1 or 1
    return vec2(150 * sx, - 150)
end

function throw.spin_once(id, throw_type)
    if stack.get(nw.component.already_did_shoot, id) then return end

    local x, y = throw.get_center(id)
    local v = throw.velocity_from_target(id) or throw.velocity_from_settings(id)
    local hitbox = throw.hitbox_from_type(throw_type)
    local assemble = throw.assemble_from_type(throw_type)
    
    if not x or not v or not hitbox then return end

    local pid = nw.ecs.id.strong()
    collision.register(pid, hitbox)
    collision.warp_to(pid, x, y)
    collision.flip_to(pid, stack.get(nw.component.mirror, id))

    if assemble then stack.assemble(assemble, pid) end

    stack.ensure(nw.component.timer, pid, 1.0)
    --stack.set(nw.component.is_ghost, pid)
    stack.set(nw.component.die_on_timer_done, pid)
    stack.set(nw.component.velocity, pid, v.x, v.y)
    stack.set(nw.component.gravity, pid)
    stack.set(nw.component.drawable, pid, nw.drawable.bump_body)
    stack.set(nw.component.bouncy, pid, 0.75)

    stack.set(nw.component.already_did_shoot, id)
end

function shooting.spin()
    for id, projectile_type in stack.view_table(nw.component.shoot) do
        shooting.handle_shoot(id, projectile_type)
    end

    for id, throw_type in stack.view_table(nw.component.throw) do
        --throw.spin_once(id, throw_type)
    end
end

function combat.spin()
    shooting.spin()
end

return combat