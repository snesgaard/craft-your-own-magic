local component = {}

function component.die_on_timer_complete() return true end

function component.expired() return true end

function component.health(hp) return hp or 0 end

function component.damage(dmg) return dmg or 0 end

function component.gravity(x, y) return vec2(x or 0, y or 800) end

function component.is_actor() return true end

function component.is_effect() return true end

function component.is_geometry() return true end

function component.event_on_timer_complete(event) return event end

return component
