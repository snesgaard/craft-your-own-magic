local Base = require "system.base"
local entity = require "system.entity"
local timer = Base()

function timer:handle_timer_update(ecs_world, id, timer, dt)
    if timer:done() then return end
    timer:update(dt)
    if not timer:done() then return end
    local cb = ecs_world:get(nw.component.on_timer_complete, id)
    if cb then cb(self.world, ecs_world:entity(id)) end
    local die = ecs_world:get(nw.component.die_on_timer_complete, id)
    if die then entity(self.world):destroy(ecs_world:entity(id)) end
end

function timer:update(dt, ecs_world)
    local timer_table = ecs_world:get_component_table(nw.component.timer)

    for id, timer in pairs(timer_table) do
        self:handle_timer_update(ecs_world, id, timer, dt)
    end
end

function timer.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function timer.handle_observables(ctx, obs, ...)
    local worlds = {...}

    for _, dt in ipairs(obs.update:pop()) do
        for _, ecs_world in ipairs(worlds) do
            timer.from_ctx(ctx):update(dt, ecs_world)
        end
    end
end

return timer.from_ctx
