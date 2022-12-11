local coleffect = require "system.collision_helper"

T("test_system_collision_helper", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity()
    local other = ecs_world:entity()

    T("collision_filter", function(T)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "cross")

        other:set(nw.component.is_terrain)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "slide")
        T:assert(coleffect().collision_filter(ecs_world, other.id, item.id) == "cross")

        item:set(nw.component.ignore_terrain)
        T:assert(coleffect().collision_filter(ecs_world, item.id, other.id) == "cross")
    end)

    T("on_collision", function(T)
        local dst = {}
        local function item_cb() dst.item_success = true end
        local function other_cb() dst.other_success = true end

        item:set(nw.component.on_collision, item_cb)
        other:set(nw.component.on_collision, other_cb)

        local colinfo = {
            item = item.id,
            other = other.id,
            ecs_world = ecs_world
        }

        coleffect():on_collision(colinfo)

        T:assert(dst.item_success)
        T:assert(dst.other_success)
    end)

    T("check_collision_once", function(T)
        item:assemble(
            nw.system.collision().assemble.init_entity,
            0, 0, nw.component.hitbox(10, 10)
        )
        other:assemble(
            nw.system.collision().assemble.init_entity,
            0, 0, nw.component.hitbox(10, 10)
        )
        item:set(nw.component.check_collision_once)
        local collisions = coleffect():check_collision_once(ecs_world)
        T:assert(not item:has(nw.component.check_collision_once))
        T:assert(collisions[item.id])
        T:assert(#collisions[item.id] == 1)
    end)
end)
