local BASE = ...

local function import(name)
    return require(BASE .. "." .. name)
end

local system = {
    base = import("base"),
    misc = import("misc"),
    timer = import("timer"),
    ball = import("ball"),
    effect = import("effect_resolution"),
    collision = import("collision_filter_and_response")
}

system.full = list(
    nw.system.motion(),
    system.base.system(system.collision.rules),
    system.base.system(system.ball.rules),
    system.base.system(system.timer),
    system.base.system(system.misc),
    system.base.system(system.effect.rules),
    nw.system.script()
)

return system
