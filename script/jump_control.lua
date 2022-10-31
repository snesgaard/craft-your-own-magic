local jump_control = class()

local function input_filter(key) return key == "space" end

local function collision_filter(col_info, id, ecs_world)
    local is_sold = nw.system.collision().is_solid(col_info)
    local is_id = col_info.item == id
    local is_normal = col_info.normal.y < -0.9
    local is_downward = ecs_world:ensure(nw.component.velocity, id).y >= 0
    -- HACK: Real solution is to fix the order of event dispatching
    if is_sold and is_id and is_normal then return true end
end

jump_control.BUFFER_TIME = 0.2

function jump_control.create(ctx, id)
    local on_ground_timer = nw.component.timer(jump_control.BUFFER_TIME, 0)
    local input_timer = nw.component.timer(jump_control.BUFFER_TIME, 0)

    local this = {
        timer = {
            on_ground = on_ground_timer,
            input = input_timer
        },
        input = ctx:listen("keypressed")
            :filter(function(key) return key == "space" end)
            :foreach(function()
                input_timer:reset()
            end),
        collision = ctx:listen("collision")
            :filter(function(all_col_info)
                return collision_filter(all_col_info, id, all_col_info.ecs_world)
            end)
            :foreach(function()
                on_ground_timer:reset()
            end),
        update = ctx:listen("update")
            :foreach(function(dt)
                on_ground_timer:update(dt)
                input_timer:update(dt)
            end)
    }

    return setmetatable(this, jump_control)
end

function jump_control:can_jump()
    return not self.timer.on_ground:done() and not self.timer.input:done()
end

function jump_control:clear()
    self.timer.on_ground:finish()
    self.timer.input:finish()
end

function jump_control:pop()
    local v = self:can_jump()
    if v then self:clear() end
    return v
end

function jump_control.speed_from_height(gravity, max_height)
    return math.sqrt(max_height * 4 * 0.5 * gravity)
end

return jump_control
