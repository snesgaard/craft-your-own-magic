local anime = require "animation_util"
local sys_timer = require "system.timer"

local sfx = {}

sfx.dagger_spray = {
    duration = 0.25,
    range = 200,
    num = 9,
    spread = math.pi * 0.25,
    run = function(opt, time)
        if time < 0 then return false end
        local time = math.min(opt.duration, time)
        local d = ease.linear(time, 0, opt.range, opt.duration)
        local alpha = ease.inExpo(time, 1, -1, opt.duration)
        gfx.setColor(1, 0, 0, alpha)
        
        for i = 1, opt.num do
            local s = opt.spread
            local r = ease.linear(i - 1, -s / 2, s, opt.num - 1)
            gfx.push()
            gfx.rotate(r)
            gfx.ellipse("fill", d, 0, 4, 1)
            gfx.pop()
        end
    end
}

sfx.bouncing_flask = {
    duration = 0.25,
    gravity = vec2(0, 300),
    run = function(opt, time, entity, init_pos, end_pos)
        local time_norm = time / opt.duration
        local pos = anime.ballistic_curve(
            time_norm, init_pos, end_pos, opt.gravity
        )
        gfx.circle("line", pos.x, pos.y, 10)
    end
}

function sfx.get_time(entity)
    return clock.get(entity:world()) - entity:ensure(nw.component.time)
end

function sfx.is_done(entity)
    return sys_timer().is_done(entity)
end

function sfx.play(ecs_world, sfx_data, ...)
    return ecs_world:entity()
        :set(nw.component.sfx_data, sfx_data, ...)
        :set(nw.component.time, clock.get(ecs_world))
        :set(nw.component.drawable, sfx.drawable)
        :set(nw.component.timer, sfx_data.duration or 0)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.layer, painter.layer.effects)
end

function sfx.drawable(entity)
    local f = entity:get(nw.component.sfx_data)
    if not f then return end
    local args = f.args
    local data = f.data
    if not data.run then return end
    
    gfx.push("all")
    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)
    local t = sfx.get_time(entity)
    data:run(t, entity, unpack(args))
    gfx.pop()
end

return sfx