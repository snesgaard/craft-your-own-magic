local painter = require "painter"

local component = {}

component.health_relation = nw.component.relation(function(id) return id end)

function component.bar_values(value, max)
    return {value=value, max=max}
end

local health_bar = {}

function health_bar.has_health_bar(entity)
    local children = nw.system.parent().get_children(entity)
    local ecs_world = entity:world()

    for id, _ in pairs(children) do
        if ecs_world:has(component.bar_values, id) then return true end
    end

    return false
end

function health_bar.should_add(ecs_world, id)
    local entity = ecs_world:entity(id)
    local has_hp = ecs_world:has(nw.component.health, id)
    local has_index = ecs_world:has(nw.component.board_index, id)
    return has_hp and has_index and not health_bar.has_health_bar(entity)
end

function health_bar.sync(entity, bar_values)
    local parent_id = nw.system.parent().get_parent(entity)
    if not parent_id then return end
    local hp = entity:world():get(nw.component.health, parent_id)
    if not hp then return end
    bar_values.value = hp.value
    bar_values.max = hp.max
end

function health_bar.spin(ecs_world)
    local board_index = ecs_world:get_component_table(nw.component.board_index)

    for id, _ in pairs(board_index) do
        if health_bar.should_add(ecs_world, id) then
            ecs_world:entity()
                :assemble(health_bar.assemble, ecs_world:entity(id))
        end
    end

    local bars = ecs_world:get_component_table(component.bar_values)
    for id, bar_values in pairs(bars) do
        health_bar.sync(ecs_world:entity(id), bar_values)
    end
end

function health_bar.drawable(entity)
    local hp = entity:get(component.bar_values)
    local area = entity:get(nw.component.mouse_rect)

    if not hp or not area then return end

    gfx.push("all")

    local parent_id = nw.system.parent().get_parent(entity)
    if parent_id then
        local parent = entity:world():entity(parent_id)
        nw.drawable.push_transform(parent)
    end
    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)

    nw.drawable.push_color(entity, 0.5)
    gfx.rectangle("fill", area.x, area.y, area.w, area.h)
    nw.drawable.push_color(entity)
    local s = hp.value / hp.max
    gfx.rectangle("fill", area.x, area.y, area.w * s, area.h)

    gfx.pop()
end

function health_bar.assemble(entity, parent)
    local w, h = 50, 2
    local w = painter.norm_to_real(0.075)
    local dy = h * 3
    entity
        :set(component.bar_values, 1, 1)
        :set(nw.component.mouse_rect, -w / 2, dy, w, h)
        :set(nw.component.color, 0.8, 0.3, 0.1)
        :set(nw.component.layer, 2)
        :set(nw.component.drawable, health_bar.drawable)
        :assemble(nw.system.parent().set_parent, parent)
end

return health_bar