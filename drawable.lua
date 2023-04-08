local gui = require "gui"
local painter = require "painter"
local combat = require "combat"

local drawable = {}

function drawable.board_actor(entity)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    local w, h = 20, 50
    gfx.rectangle("fill", -w / 2, -h, w, h)

    gfx.pop()

    drawable.ai_intent(entity)
end

function drawable.target_marker(entity)
    local id = entity:get(nw.component.parent)
    
    if not id then return end
    gfx.push("all")

    local ecs_world = entity:world()
    nw.drawable.push_transform(ecs_world:entity(id))
    nw.drawable.push_state(entity)

    gfx.circle("line", 0, 0, 10)

    gfx.pop()
end

function drawable.single_target_marker(entity)
    local id = gui.menu.get_selected_item(entity)
    if not id then return end

    gfx.push("all")

    local ecs_world = entity:world()
    nw.drawable.push_transform(ecs_world:entity(id))
    nw.drawable.push_state(entity)

    gfx.circle("line", 0, 0, 10)

    gfx.pop()
end

function drawable.target_marker(entity)
    local targets = gui.menu.get_selected_item(entity)
    if not targets then return end

    gfx.push("all")
    nw.drawable.push_state(entity)
    
    local ecs_world = entity:world()
    for _, id in ipairs(targets) do
        gfx.push()
        nw.drawable.push_transform(ecs_world:entity(id))
        gfx.circle("line", 0, 0, 10)
        gfx.pop()
    end

    gfx.pop()
end

local function compute_vertical_offset(valign, font, h)
    if valign == "top" then
		return 0
	elseif valign == "bottom" then
		return h - font:getHeight()
    else
        return (h - font:getHeight()) / 2
	end
end

local function draw_text(text, shape, align, valign)
    local dy = compute_vertical_offset(valign, gfx.getFont(), shape.h)
    gfx.printf(text, shape.x, shape.y + dy, shape.w, align)
end

drawable.draw_text = draw_text

function drawable.text(entity)
    local text = entity:get(nw.component.text)
    local mouse_rect = entity:get(nw.component.mouse_rect)
    if not text or not mouse_rect then return end

    gfx.push("all")

    nw.drawable.push_state(entity)
    nw.drawable.push_transform(entity)

    local align = entity:get(nw.component.align) or "center"
    local valign = entity:get(nw.component.valign) or "center"
    painter.draw_text(
        text, mouse_rect, {align=align, valign=valign, font=painter.font(48)}
    )

    gfx.pop()
end

function drawable.vertical_menu(entity)
    local menu_state = entity:get(nw.component.linear_menu_state)
    if not menu_state then return end

    gfx.push("all")

    nw.drawable.push_state(entity)
    nw.drawable.push_transform(entity)

    local item_shape = spatial(0, 0, 30, 10)
    local item_margin = 1

    love.graphics.setLineWidth(1)

    local to_text = entity:ensure(nw.component.linear_menu_to_text)

    for index, item in ipairs(menu_state.items) do
        if index == menu_state.index and not menu_state.confirmed then
            gfx.setColor(0.8, 0.4, 0)
            gfx.rectangle("line", item_shape:unpack())
        end

        if menu_state.confirmed and index == menu_state.index then
            gfx.setColor(0.8, 0.4, 0)
        else
            gfx.setColor(1, 1, 1)
        end
        gfx.rectangle("fill", item_shape:unpack())

        gfx.setColor(0, 0, 0)
        painter.draw_text(
            to_text(item), item_shape,
            {align="center", valign="center", font=painter.font(24)}
        )
        
        item_shape = item_shape:down(0, item_margin)
    end

    gfx.pop()
end

function drawable.ellipse(entity)
    gfx.push("all")
    nw.drawable.push_state(entity)
    nw.drawable.push_transform(entity)
    gfx.ellipse("fill", 0, 0, 1)
    gfx.pop()
end

local function read_energy(entity)
    local parent = entity:get(nw.component.parent)
    if not parent then return "NA" end
    return entity:world():ensure(nw.component.energy, parent)
end

function drawable.energy_meter(entity)
    local x, y = painter.norm_to_real(0, 1)
    local area = entity:ensure(nw.component.mouse_rect, x + 5, y - 25, 20, 20)

    gfx.push("all")

    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)

    local energy = read_energy(entity)
    gfx.setColor(0.1, 0.6, 0.2)
    gfx.ellipse(
        "fill", area.w / 2 + area.x, area.h / 2 + area.y, area.w / 2, area.h / 2
    )
    gfx.setColor(1, 1, 1)
    painter.draw_text(
        tostring(energy), area, {align="center", valign="center", font=painter.font(64)}
    )

    gfx.pop()
end

function drawable.ai_intent(entity)
    local action = combat.ai.get_next_action(entity:world(), entity.id)
    local rect = entity:get(nw.component.mouse_rect)
    if not action or not rect then return end

    gfx.push("all")

    nw.drawable.push_transform(entity)
    local text_area = rect:up(0, 5)
    gfx.setColor(1, 1, 1)
    painter.draw_text(
        tostring(action.name or "nonname"), text_area,
        {align="center", valign="bottom", font=painter.font(24)}
    )

    gfx.pop()
end

return drawable