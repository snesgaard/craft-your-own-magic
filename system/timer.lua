local rules = {}

local function handle_event_on_complete(ctx, entity)
    local event = entity:get(nw.component.event_on_timer_complete)

    if not event then return end
    
    if type(event) == "function" then
        ctx:emit(event(entity))
    else
        ctx:emit(event, entity)
    end
end

local function handle_timer(ctx, dt, entity, timer)
    if timer:done() then return end
    timer:update(dt)
    if not timer:done() then return end
    ctx:emit("timer_completed", entity.id)
    handle_event_on_complete(ctx, entity)
end

function rules.update(ctx, dt, ecs_world)
    local component_table = ecs_world:get_component_table(nw.component.timer)
    for id, timer in pairs(component_table) do
        handle_timer(ctx, dt, ecs_world:entity(id), timer)
    end
end

function rules.timer_completed(ctx, id, ecs_world)
    if ecs_world:get(nw.component.die_on_timer_complete, id) then
        ctx:emit("destroy", id)
    end
end

return rules
