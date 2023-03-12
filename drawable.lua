local drawable = {}

function drawable.board_actor(entity)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    local w, h = 40, 100
    gfx.rectangle("fill", -w / 2, -h, w, h)

    gfx.pop()
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
    draw_text(text, mouse_rect, align, valign)

    gfx.pop()
end

function drawable.vertical_menu(entity)
    local menu_state = entity:get(nw.component.linear_menu_state)
    if not menu_state then return end

    gfx.push("all")

    nw.drawable.push_state(entity)
    nw.drawable.push_transform(entity)

    local item_shape = spatial(0, 0, 100, 20)
    local item_margin = 5

    love.graphics.setLineWidth(5)

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
        draw_text(item, item_shape, "center", "center")
        
        item_shape = item_shape:down(0, item_margin)
    end

    gfx.pop()
end

return drawable