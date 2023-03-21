local input = require "system.input"

local log = {}

log.width = 300
log.height = 200
log.font = gfx.newFont()
log.margin = 5
log.fade_duration = 0
log.fade_begin = 1

log.level = {
    debug = 1,
    info = 2,
    warning = 3,
    error = 4
}

function log.update(ecs_world, dt)

end

function log.spin(ecs_world)
    if input.is_pressed(ecs_world, "+") then
        local data = ecs_world:entity(log)
        local v = data:ensure(nw.component.visible)
        data:set(nw.component.visible, not v)
    end

end

function log.compute_alpha(time)
    if log.fade_duration <= 0 then return 1 end
    local dt = love.timer.getTime() - time
    return math.min(1, ease.linear(dt - log.fade_begin, 1, -1, log.fade_duration))
end

function log.create_text(message)
    local text_width = log.width - 2 * log.margin
    local text = gfx.newText(log.font)
    text:addf(message, text_width, "left", 0, 0)
    return text
end

function log.draw(ecs_world)
    if not ecs_world:ensure(nw.component.visible, log) then return end

    local entries = ecs_world:get_component_table(nw.component.log_entry)
        :values()
        :sort(function(v1, v2) return v1.time > v2.time end)
        :filter(function(v) return log.compute_alpha(v.time) > 0 end)

    if entries:empty() then return end
    
    gfx.push("all")
    
    gfx.setColor(0.1, 0.2, 0.8, 0.3)
    gfx.rectangle("fill", 0, 0, log.width, log.height)

    local y = log.height
    local x = log.margin
    for _, entry in ipairs(entries) do
        entry.text = entry.text or log.create_text(entry.message)
        y = y - entry.text:getHeight() - log.margin
        local alpha = log.compute_alpha(entry.time)
        local ly = y - log.margin / 2
        gfx.setColor(1, 1, 1, 0.25 * alpha)
        gfx.line(x, ly, log.width - log.margin, ly)
        gfx.setColor(1, 1, 1, alpha)
        gfx.draw(entry.text, x, y)

    end

    gfx.pop()
end

function log.info(ecs_world, message)
    ecs_world:entity():set(nw.component.log_entry, message, log.level.info)
end

return log