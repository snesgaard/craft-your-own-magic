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

local function patrol_initial_position(entity, patrol_positions)
    local pos = entity:get(nw.component.position) or vec2()
    return patrol_positions
        :map(function(p) return (p - pos):length() end)
        :argsort()
        :head()
end

function rh.patrol(ctx, entity, patrol_positions, speed, wait_time)
    if #patrol_positions == 0 then return end

    local init = patrol_initial_position(entity, patrol_positions)
    for i = init, #patrol_positions do
        local pos = patrol_positions[i]
        rh.move(ctx, entity, pos, speed)
        rh.wait(ctx, wait_time)
    end
end

return setmetatable(rh, rh)
