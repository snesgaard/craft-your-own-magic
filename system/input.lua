local Base = require "system.base"
local Input = Base()

local function get_axis_dir(neg_down, pos_down)
    local v = 0
    if neg_down then v = v - 1 end
    if pos_down then v = v + 1 end

    return v
end

function Input.x()
    return get_axis_dir(love.keyboard.isDown("left"), love.keyboard.isDown("right"))
end

function Input.y()
    return get_axis_dir(love.keyboard.isDown("w"), love.keyboard.isDown("s"))
end

return Input.from_ctx
