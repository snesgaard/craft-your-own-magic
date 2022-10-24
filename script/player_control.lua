local JumpControl = require "script.jump_control"

local function x_dir()
    local neg = love.keyboard.isDown("left") and -1 or 0
    local pos = love.keyboard.isDown("right") and 1 or 0
    return neg + pos
end

local speed = 300

local function compute_jump_speed(entity)
    local gravity = entity:get(nw.component.gravity)
    if not gravity then return 0 end
    return JumpControl.speed_from_height(gravity.y, 50)
end

return function(ctx, entity)
    local update = ctx:listen("update"):collect()
    local jump = JumpControl.create(ctx, entity.id)

    ctx:spin(function(ctx)
        for _, dt in ipairs(update:peek()) do
            nw.system.collision():move(entity, x_dir() * speed * dt, 0)
        end

        if jump:pop() then
            entity:map(nw.component.velocity, function(v)
                return vec2(v.x, -compute_jump_speed(entity))
            end)
        end
    end)
end
