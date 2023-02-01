local rh = {}

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

return setmetatable(rh, rh)
