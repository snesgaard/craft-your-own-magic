local rules = {}

local function same_team(a, b)
    return a:get(nw.component.team) == b:get(nw.component.team)
end

local function trigger_damage(source, target, effect)
    if not effect.damage then return end
    if same_team(source, target) then return end
    return combat.damage(target, effect.damage)
end

local function trigger_heal(source, target, effect)
    if not effect.heal then return end
    if not same_team(source, target) then return end
    return combat.heal(target, effect.heal)
end

local function trigger_terrain(source, target, effect)
    if not effect.trigger_on_terrain then return end
    if not target:get(nw.component.terrain) then return end
    return true
end

local effects = {
    {
        name = "damage",
        func = trigger_damage
    },
    {
        name = "heal",
        func = trigger_heal
    },
    {
        name = "trigger_on_terrain",
        func = trigger_on_terrain
    }
}

local function should_trigger(source, target)
    if source:get(nw.component.trigger_once) then
        return not source:get(nw.component.already_triggered)
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
            if not t:done() then return false
            t:reset()
        else
            data.timers[target.id] = nw.component.timer(data.interval)
        end
        return true
    end

    return false
end

local function handle_event_on_trigger(source, target, info)
    if not source:get(nw.component.event_on_trigger) then return end

    local event = source:get(nw.component.event_on_trigger)

    if type(event) == "function" then
        ctx:emit(event(source, target, info))
    else
        ctx:emit(event, source, target, info)
    end
end

function rules.trigger_effect(ctx, source, target)
    local effect = source:get(nw.component.effect)
    if not effect then return end

    if source:get(nw.component.expired) then return end

    local info = dict()

    for _, effect in ipairs(effects) do
        info[effect.name] = effect.func(effect, target)
    end

    if dict:empty() then return end

    ctx:emit("on_trigger_effect", source, target, info)

    if source:get(nw.component.expire_on_trigger) then
        source:set(nw.component.expired)
    end

    handle_event_on_trigger(source, target, info)
end

function rules.collision(ctx, colinfo)
    local item = colinfo.ecs_world:entity(colinfo.item)
    local other = colinfo.ecs_world:entity(colinfo.other)
    rules.trigger_effect(ctx, source, target)
    rules.trigger_effect(ctx, target, source)
end
