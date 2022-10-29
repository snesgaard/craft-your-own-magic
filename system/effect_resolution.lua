local sub_rules = {}

local rules = {}

function sub_rules.should_trigger(source, target)
    if source:get(nw.component.trigger_once) then
        if source:get(nw.component.already_triggered) then return false end
        source:set(nw.component.already_triggered)
        return true
    end

    if source:get(nw.component.trigger_once_pr_entity) then
        local registry = source:get(nw.component.trigger_once_pr_entity)
        if registry[target.id] then return false end
        registry[target.id] = true
        return true
    end

    if source:get(nw.component.trigger_on_interval) then
        local data = source:get(nw.component.trigger_on_interval)
        local t = data.timers[target.id]
        if t then
            if not t:done() then return false end
            t:reset()
        else
            data.timers[target.id] = nw.component.timer(data.interval)
        end
        return true
    end

    return false
end

function sub_rules.handle_event_on_trigger(source, target, info)
    if not source:get(nw.component.event_on_trigger) then return end

    local event = source:get(nw.component.event_on_trigger)

    if type(event) == "function" then
        ctx:emit(event(source, target, info))
    else
        ctx:emit(event, source, target, info)
    end
end

local function call_effect(info, source, target, func, ...)
    info[func] = func(source, target, ...)
end

function sub_rules.trigger_effect(ctx, source, target)
    local info = dict()
    if not sub_rules.should_trigger(source, target) then
        return info
    end
    local effect = source:get(nw.component.effect)
    if not effect then return info end

    if source:get(nw.component.expired) then return info end


    for _, e in ipairs(effect) do
        call_effect(info, source, target, unpack(e))
    end

    if info:empty() then return info end

    ctx:emit("on_trigger_effect", source, target, info)

    if source:get(nw.component.expire_on_trigger) then
        source:set(nw.component.expired)
    end

    sub_rules.handle_event_on_trigger(source, target, info)

    return info
end

function rules.collision(ctx, colinfo)
    local item = colinfo.ecs_world:entity(colinfo.item)
    local other = colinfo.ecs_world:entity(colinfo.other)
    sub_rules.trigger_effect(ctx, source, target)
    sub_rules.trigger_effect(ctx, target, source)
end

function rules.update(ctx, dt, ecs_world)
    local comp_table = ecs_world:get_component_table(
        nw.component.trigger_on_interval
    )

    for _, data in pairs(comp_table) do
        for _, timer in pairs(data.timers) do
            timer:update(dt)
        end
    end
end

return {
    rules = rules,
    sub_rules = sub_rules
}
