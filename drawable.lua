local drawable = {}

function drawable.board_actor(entity)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    local w, h = 40, 100
    gfx.rectangle("fill", -w / 2, -h, w, h)

    gfx.pop()
end

function drawable.target_marker(entity)
    gfx.push("all")

    local id = entity:get(nw.component.parent)

    if not id then return end

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

function drawable.text(entity)
    local text = entity:get(nw.component.text)
    local mouse_rect = entity:get(nw.component.mouse_rect)
    if not text or not mouse_rect then return end

    gfx.push("all")

    nw.drawable.push_state(entity)
    nw.drawable.push_transform(entity)

    local align = entity:get(nw.component.align) or "center"
    local valign = entity:get(nw.component.valign) or "center"
    local dy = compute_vertical_offset(valign, gfx.getFont(), mouse_rect.h)
    gfx.printf(text, mouse_rect.x, mouse_rect.y + dy, mouse_rect.w, align)

    gfx.pop()
end

return drawable