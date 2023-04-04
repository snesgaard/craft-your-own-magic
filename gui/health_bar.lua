local painter = require "painter"
local combat = require "combat"

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


function health_bar.spin(ecs_world)
    ecs_world:entity("healthbar_drawer")
        :init(nw.component.layer, painter.layer.field_gui)
        :init(nw.component.drawable, health_bar.drawable)
end

function health_bar.draw_health_bar(area, value, max)
    gfx.push("all")

    gfx.setColor(0.8, 0.3, 0.1, 0.5)
    gfx.rectangle("fill", area.x, area.y, area.w, area.h)
    gfx.setColor(0.8, 0.3, 0.1)
    local s = value / max
    gfx.rectangle("fill", area.x, area.y, area.w * s, area.h)

    gfx.pop()
end

local status_color = {
    [combat.status.cultist_power] = {0.2, 0.4, 0.8},
    [combat.status.strength] = {0.8, 0.4, 0.2}
}

local status_order = list(combat.status.cultist_power, combat.status.strength)

local function draw_status_cell(color, cell, value)
    if not value or value == 0 or not color then return false end

    gfx.setColor(color)
    gfx.rectangle("fill", cell:unpack())
    gfx.setColor(1, 1, 1)
    painter.draw_text(value, cell, {align="center", valign="center", font=painter.font(24)})
    return true
end

function health_bar.draw_status_bar(entity, status_bar_shape)
    local row = spatial(status_bar_shape.x, status_bar_shape.y, 6, 6)
    local cell = row

    for _, status in ipairs(status_order) do
        local value = entity:get(status)
        local color = status_color[status]
        if draw_status_cell(color, cell, value) then cell = cell:right(2, 0) end
    end
end

function health_bar.drawable(entity)
    local ecs_world = entity:world()
    gfx.push("all")

    local health_bar_shape = spatial():expand(25, 2)
    local status_bar_shape = health_bar_shape:down(0, 4, nil, 100)
    gfx.setColor(0.8, 0.3, 0.1)
    for id, hp in pairs(ecs_world:get_component_table(nw.component.health)) do
        gfx.push("all")
        local entity = ecs_world:entity(id)
        nw.drawable.push_transform(entity)
        gfx.translate(0, 10)
        health_bar.draw_health_bar(health_bar_shape, hp.value, hp.max)
        health_bar.draw_status_bar(entity, status_bar_shape)
        gfx.pop()
    end


    gfx.pop()
end

return health_bar