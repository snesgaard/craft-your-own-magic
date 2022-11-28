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
    collision = import("collision_filter_and_response"),
    ui = import("ui"),
    barrel = import("barrel")
}

system.full = list(
    nw.system.motion(),
    nw.system.camera,
    system.base.system(system.collision.rules),
    system.base.system(system.ball.rules),
    system.base.system(system.barrel.rules),
    system.base.system(system.timer),
    system.base.system(system.misc),
    system.base.system(system.effect.rules),
    nw.system.script(),
    system.base.system(system.ui.rules)
)

return system
