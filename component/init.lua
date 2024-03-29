local component = {}

function component.die_on_timer_complete() return true end

function component.expired() return true end

function component.health(hp) return hp or 0 end

function component.max_health(hp) return hp or 0 end

function component.health(hp, max)
    if not max then
        return {
            value = hp,
            max = hp
        }
    else
        return {
            value = hp,
            max = max
        }
    end
end

function component.damage(dmg) return dmg or 0 end

function component.gravity(x, y) return vec2(x or 0, y or 800) end

function component.is_actor() return true end

function component.is_effect() return true end

function component.is_terrain() return true end

function component.on_timer_complete(func) return func end

function component.trigger_once() return true end

function component.already_triggered() return true end

function component.trigger_once_pr_entity() return dict() end

function component.on_collision(cb) return cb end

function component.trigger_on_interval(interval)
    if not interval then errorf("You must give an interval") end
    return {timers=dict(), interval=interval}
end

function component.effect(...)
    local effects = list(...)
    for _, effect in ipairs(effects) do
        if type(effect[1]) ~= "function" then
            errorf("First effect argument must be a function, but was %s", type(effect[1]))
        end
    end
    return effects
end

function component.expire_on_trigger() return true end

function component.event_on_effect_trigger(event) return event end

function component.team(team) return team end

function component.ignore_terrain() return true end

function component.bouncy(b) return b end

function component.check_collision_once() return true end

function component.layer(l) return l or 0 end

function component.order(o) return o or 0 end

function component.event_on_death(f) return f end

function component.invincible(v) return v or 0 end

function component.dead() return true end

function component.brittle() return true end

function component.on_death(f) return f end

function component.jump_request(cooldown)
    return nw.component.timer(cooldown or 0.2)
end

function component.jump_on_ground(cooldown)
    return nw.component.timer(cooldown or 0.2)
end

function component.jump(height)
    return height
end

-- INPUT

function component.keypressed(key) return key end

function component.keyreleased(key) return key end

function component.mousepressed(x, y, button, is_touch)
    return {x = x, y = y, button = button, is_touch = is_touch}
end

function component.mousereleased(x, y, button, is_touch)
    return {x = x, y = y, button = button, is_touch = is_touch}
end

function component.mousemoved(x, y, dx, dy)
    return {x = x, y = y, dx = dx, dy = dy}
end

function component.element_clicked(id) return id end
function component.element_released(id) return id end

function component.pressed() return true end
function component.released() return true end
function component.is_down() return true end

function component.mouse_rect(x, y, w, h) return spatial(x, y, w, h) end

function component.update(dt) return dt end

function component.slider(value, min, max)
    return {value=value, min=min, max=max}
end

return component
