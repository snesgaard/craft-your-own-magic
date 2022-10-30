local component = {}

function component.die_on_timer_complete() return true end

function component.expired() return true end

function component.health(hp) return hp or 0 end

function component.damage(dmg) return dmg or 0 end

function component.gravity(x, y) return vec2(x or 0, y or 800) end

function component.is_actor() return true end

function component.is_effect() return true end

function component.is_terrain() return true end

function component.event_on_timer_complete(event) return event end

function component.trigger_once() return true end

function component.already_triggered() return true end

function component.trigger_once_pr_entity() return dict() end

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

return component
