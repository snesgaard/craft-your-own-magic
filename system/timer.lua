local rules = {}

local function handle_timer(ctx, dt, id, timer)
    if timer:done() then return end
    timer:update(dt)
    if timer:done() then ctx:emit("timer_completed", id) end
end

function rules.update(ctx, dt, ecs_world)
    local component_table = ecs_world:get_component_table(nw.component.timer)
    for id, timer in pairs(component_table) do
        handle_timer(ctx, dt, id, timer)
    end
end

function rules.timer_completed(ctx, id, ecs_world)
    if ecs_world:get(nw.component.die_on_timer_complete, id) then
        ctx:emit("destroy", id)
    end
end

return rules
