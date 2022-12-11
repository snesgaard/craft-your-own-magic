local Base = require "system.base"
local CollisionHelper = Base()

function CollisionHelper:invoke_on_collision(colinfo, item, other)
    local on_collision = item:get(nw.component.on_collision)
    if not on_collision then return end
    on_collision(self.world, item, other, colinfo)
end

function CollisionHelper:on_collision(colinfo)
    local item = colinfo.ecs_world:entity(colinfo.item)
    local other = colinfo.ecs_world:entity(colinfo.other)

    self:invoke_on_collision(colinfo, item, other)
    self:invoke_on_collision(colinfo, other, item)
end

function CollisionHelper.collision_filter(ecs_world, item, other)
    local item = ecs_world:entity(item)
    local other = ecs_world:entity(other)

    if other:has(nw.component.is_terrain) then
        if item:has(nw.component.ignore_terrain) then return "cross" end

        return item:has(nw.component.bouncy) and "bounce" or "slide"
    end

    return "cross"
end

function CollisionHelper:check_collision_once(ecs_world)
    local collisions = {}

    for id, _ in pairs(ecs_world:get_component_table(nw.component.check_collision_once)) do
        local _, _, col = nw.system.collision(self.world)
            :move(ecs_world:entity(id), 0, 0)
        collisions[id] = col
        ecs_world:remove(nw.component.check_collision_once, id)
    end

    return collisions
end

return CollisionHelper.from_ctx
