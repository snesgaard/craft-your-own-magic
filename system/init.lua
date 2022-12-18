local function import(name)
    return require("system." .. name)
end

local system_order = list(
    nw.system.motion,
    nw.system.camera,
    import("trigger"),
    import("timer"),
    import("collision_helper"),
    import("jump"),
    nw.system.script
)

local function observables(sys, ctx)
    if type(sys) == "function" then
        return sys().observables(ctx)
    elseif type(sys) == "table" then
        return sys.observables(ctx)
    end
end

local function handle_observables(sys, ctx, obs, ...)
    if type(sys) == "function" then
        return sys().handle_observables(ctx, obs, ...)
    elseif type(sys) == "table" then
        return sys.handle_observables(ctx, obs, ...)
    end
end

local api = {}

api.order = system_order

function api.observables_and_system(ctx)
    return system_order:map(function(system)
        return {
            system = system,
            obs = observables(system, ctx)
        }
    end)
end

function api.handle_observables(ctx, obs, ...)
    for _, sys_obs in ipairs(obs) do
        handle_observables(sys_obs.system, ctx, sys_obs.obs, ...)
    end
end

nw.system.input = import("input")
nw.system.timer = import("timer")
nw.system.trigger = import("trigger")
nw.system.collision_helper = import("collision_helper")
nw.system.entity = import("entity")
nw.system.combat = import("combat")
nw.system.jump = import("jump")

nw.system.collision_helper().set_default_filter()

return api
