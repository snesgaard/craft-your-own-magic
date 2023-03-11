local rh = {}

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

function rh.spin(ecs_world3)
    rh.health_bar.spin(ecs_world)
end

return setmetatable(rh, rh)
