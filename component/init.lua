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

function component.player_team() return true end

function component.enemy_team() return true end

function component.turn_order(l) return l end

function component.board_index(i) return i end

function component.linear_menu_state(items, index)
    return {
        index = index or 1,
        items = items or list()
    }
end

function component.linear_menu_filter(f) return f end

function component.linear_menu_to_text(func) return func or tostring end

function component.keybinding(k) return k end

function component.focus() return true end

function component.animated_action(func, ...)
    return {
        func = func,
        args = {...}
    }
end

function component.tween_callback(func, ...)
    return func
end

function component.flag() return {} end

function component.log_entry(message, level)
    return {
        message = message,
        level = level,
        time = love.timer.getTime()
    }
end

function component.deck(d) return d or list() end

function component.player_card_state(state)
    return state or {
        draw = list(),
        discard = list(),
        hand = list(),
        incant = list(),
        executed = list()
    }
end

function component.player_turn(user)
    return {
        user = user
    }
end

function component.card_select_stage(user, cards)
    return dict{
        cards = cards,
        confirmed = false,
        user = user
    }
end

function component.target_select_stage(user, ability, index)
    return {
        user = user,
        ability = ability,
        index = index
    }
end

function component.energy(level)
    return level or 0
end

function component.enery_refill(level)
    return level or 0
end

function component.enemy_turn() return {} end

function component.turn(is_player) return {is_player = is_player} end

function component.no_cancel() return true end

function component.ai_state(draw, discard, exhaust)
    return {
        draw = draw or list(),
        discard = discard or list(),
        exhaust = exhaust or list(),
        intent = nil
    }
end

function component.ai_deck(deck) return deck or list() end

return component
