local rh = {}

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

local function wait_reductor(time, dt)
    return time - dt
end

local function wait_check(time)
    return time <= 0
end

function rh.wait(ctx, duration)
    local is_done = ctx:listen("update")
        :reduce(wait_reductor, duration)
        :map(wait_check)
        :latest()

    ctx:spin(function() return is_done:peek() end)
end

return setmetatable(rh, rh)
