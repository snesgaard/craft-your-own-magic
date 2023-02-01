local Base = nw.system.base
local collision_helper = require "system.collision_helper"
local Jump = Base()

function Jump.speed_from_height(gravity, max_height)
    return math.sqrt(max_height * 4 * 0.5 * gravity)
end

function Jump.execute_jump(entity)
    local jump_height = entity:get(nw.component.jump)
    local gravity = entity:get(nw.component.gravity)
    if not jump_height or not gravity then return false end
    local vy = Jump.speed_from_height(gravity.y, jump_height)
    entity:set(nw.component.velocity, 0, -vy)
    return true
end

function Jump:jump_if_can(entity)
    local req_timer = entity:get(nw.component.jump_request)
    local g_timer = entity:get(nw.component.jump_on_ground)
    if not req_timer or not g_timer then return false end
    if req_timer:done() or g_timer:done() then return false end
    if not Jump.execute_jump(entity) then return false end
    req_timer:finish()
    g_timer:finish()
    local info = {entity = entity}
    self:emit("on_jump", info)
    return true
end

function Jump:update(dt, ecs_world)
    local request_table = ecs_world:get_component_table(
        nw.component.jump_request
    )
    local on_ground_table = ecs_world:get_component_table(
        nw.component.jump_on_ground
    )

    for id, req_timer in pairs(request_table) do
        self:jump_if_can(ecs_world:entity(id))
    end

    for id, timer in pairs(request_table) do timer:update(dt) end
    for id, timer in pairs(on_ground_table) do timer:update(dt) end
end

function Jump:on_collision(colinfo)
    local item = colinfo.ecs_world:entity(colinfo.item)
    local is_solid = collision_helper().is_solid(colinfo.type)
    local is_upward = colinfo.normal.y <= -0.9
    local v = item:get(nw.component.velocity)
    local vy = v and v.y or 0
    if not is_solid or not is_upward or vy < 0 then return end
    item:set(nw.component.jump_on_ground)
end

function Jump:request(entity, height)
    entity:set(nw.component.jump_request)
    if height then entity:set(nw.component.jump, height) end
end

function Jump:is_on_ground(entity)
    local g_timer = entity:get(nw.component.jump_on_ground)
    return g_timer and not g_timer:done()
end

function Jump.observables(ctx)
    return {
        update = ctx:listen("update"):collect(),
        collision = ctx:listen("collision"):collect()
    }
end

function Jump.handle_observables(ctx, obs, ...)
    for _, colinfo in ipairs(obs.collision:pop()) do
        Jump.from_ctx(ctx):on_collision(colinfo)
    end

    for _, ecs_world in ipairs{...} do
        for _, dt in ipairs(obs.update:pop()) do
            Jump.from_ctx(ctx):update(dt, ecs_world)
        end
    end
end

return Jump.from_ctx
