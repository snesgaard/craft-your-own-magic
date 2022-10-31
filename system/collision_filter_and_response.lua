local nw = require "nodeworks"

local comp = nw.component

local function solid_collision(item, other)
    return item:has(comp.bouncy) and "bounce" or "slide"
end

local function collision_filter(ecs_world, item, other)
    local item = ecs_world:entity(item)
    local other = ecs_world:entity(other)

    if other:has(comp.is_terrain) then
        if item:has(comp.ignore_terrain) then return "cross" end

        return solid_collision(item, other)
    end

    return "cross"
end

local sub_rules = {}
local rules = {}

function sub_rules.handle_bounce(ctx, colinfo)
    if colinfo.type ~= "bounce" then return end
    local bounce = colinfo.ecs_world:get(comp.bouncy, colinfo.item)
    local v = colinfo.ecs_world:get(comp.velocity, colinfo.item)
    if not bounce or not v then return end

    local n = vec2(colinfo.normal.x, colinfo.normal.y)
    local next_v = v - (1 + bounce) * (v:dot(n)) * n
    colinfo.ecs_world:set(comp.velocity, colinfo.item, next_v.x, next_v.y)
end

function rules.collision(ctx, colinfo)
    sub_rules.handle_bounce(ctx, colinfo)
end

return {
    rules = rules,
    sub_rules = sub_rules,
    collision_filter = collision_filter
}
