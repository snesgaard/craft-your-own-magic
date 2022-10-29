local effect_resolution = require "system.effect_resolution"
local sub_rules = effect_resolution.sub_rules
local rules = effect_resolution.rules

T("effect_resolution", function(T)
    local ctx = TestContext.create()
    local ecs_world = nw.ecs.entity.create()

    local source = ecs_world:entity()
    local target = ecs_world:entity()
    local other = ecs_world:entity()

    T("should_trigger_none", function(T)
        T:assert(not sub_rules.should_trigger(source, target))
    end)

    T("should_trigger_once", function(T)
        source:set(nw.component.trigger_once)

        T:assert(sub_rules.should_trigger(source, target))
        T:assert(not sub_rules.should_trigger(source, target))
        T:assert(not sub_rules.should_trigger(source, other))
    end)

    T("should_trigger_once_pr_entity", function(T)
        source:set(nw.component.trigger_once_pr_entity)

        T:assert(sub_rules.should_trigger(source, target))
        T:assert(not sub_rules.should_trigger(source, target))
        T:assert(sub_rules.should_trigger(source, other))
        T:assert(not sub_rules.should_trigger(source, other))
    end)

    T("should_trigger_interval", function(T)
        source:set(nw.component.trigger_on_interval, 1.0)

        T:assert(sub_rules.should_trigger(source, target))
        T:assert(not sub_rules.should_trigger(source, target))
        rules.update(ctx, 0.1, ecs_world)
        T:assert(not sub_rules.should_trigger(source, target))
        rules.update(ctx, 2.0, ecs_world)
        T:assert(sub_rules.should_trigger(source, target))
        T:assert(not sub_rules.should_trigger(source, target))
    end)

    T("effect_trigger", function(T)
        local info = sub_rules.trigger_effect(ctx, source, target)
        T:assert(sub_rules.trigger_effect(ctx, source, target):empty())

        local dst = {}
        local function effect_to_be_triggered()
            dst.was_triggered = true
            return 22
        end

        source
            :set(nw.component.effect, {effect_to_be_triggered})
            :set(nw.component.trigger_once)
        local info = sub_rules.trigger_effect(ctx, source, target)
        T:assert(dst.was_triggered)
        T:assert(info[effect_to_be_triggered])
    end)
end)
