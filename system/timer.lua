local Base = nw.system.base
local entity = require "system.entity"
local timer = Base()

function timer:handle_timer_update(ecs_world, id, timer, dt)
    if timer:done() then return end
    timer:update(dt)
    return timer:done()
end

function timer:handle_finished(ecs_world, id)
    local cb = ecs_world:get(nw.component.on_timer_complete, id)
    if cb then cb(self.world, ecs_world:entity(id)) end
    local die = ecs_world:get(nw.component.die_on_timer_complete, id)
    if die then entity(self.world):destroy(ecs_world:entity(id)) end
end

function timer:update(dt, ecs_world)
    local timer_table = ecs_world:get_component_table(nw.component.timer)

    local was_finished = {}
    for id, timer in pairs(timer_table) do
        was_finished[id] = self:handle_timer_update(ecs_world, id, timer, dt)
    end

    for id, finished in pairs(was_finished) do
        if finished then self:handle_finished(ecs_world, id) end
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
        for id, ecs_world in ipairs(worlds) do
            timer.from_ctx(ctx):update(dt, ecs_world)
        end
    end
end

function timer.is_done(entity)
    local timer = entity:get(nw.component.timer)
    if not timer then return true end
    return timer:done()
end

function timer.spin(ecs_world)
    local updates = ecs_world:get_component_table(nw.component.update)

    for _, dt in pairs(updates) do
        timer.from_ctx():update(dt, ecs_world)
    end
end

return timer.from_ctx
