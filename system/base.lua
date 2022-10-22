local base = {}

function base.observables_from_rules(ctx, rules)
    local obs = {}

    for name, _ in pairs(rules) do
        obs[name] = ctx:listen(name):collect()
    end

    return obs
end

local function update_rule(ctx, name, observable, rules, ecs_world)
    local rule = rules[name]
    if not rule then return end
    for _, value in ipairs(observable:peek()) do
        rule(ctx, value, ecs_world)
    end
end

function base.handle_observables(ctx, obs, rules, ecs_world, ...)
    if not ecs_world then return end

    for name, o in pairs(obs) do update_rule(ctx, name, o, rules, ecs_world) end

    return base.handle_observables(ctx, obs, rules, ...)
end

function base.system(rules)
    return {
        observables = function(ctx)
            return base.observables_from_rules(ctx, rules)
        end,
        handle_observables = function(ctx, obs, ecs_world, ...)
            return base.handle_observables(ctx, obs, rules, ecs_world, ...)
        end
    }
end

return base
