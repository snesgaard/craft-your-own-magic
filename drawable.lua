local gui = require "gui"
local painter = require "painter"
local combat = require "combat"
local transform = require "system.transform"

local drawable = {}

drawable.old_push_transform = nw.drawable.push_transform

function drawable.push_transform(entity)
    drawable.old_push_transform(entity)
end

local function get_frame(entity)
    if entity:get(nw.component.player_team) then
        return get_atlas("art/characters"):get_frame("witch")
    else
        return get_atlas("art/characters"):get_frame("barrel")
    end
end

function drawable.board_actor(entity)
    gfx.push("all")
    local frame = get_frame(entity)

    nw.drawable.push_transform(entity)
    local w, h = 20, 50
    --gfx.rectangle("fill", -w / 2, -h, w, h)
    frame:draw("body")

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

    gfx.translate(transform.position(entity))
    local text_area = rect:up(0, 5)
    gfx.setColor(1, 1, 1)
    painter.draw_text(
        tostring(action.name or "nonname"), text_area,
        {align="center", valign="bottom", font=painter.font(24)}
    )

    gfx.pop()
end

function drawable.dagger_spray(entity)
    local timer = entity:get(nw.component.timer)
    if not timer or timer:done() then return end

    local time = timer:inverse_normalized()

    gfx.push("all")

    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)

    gfx.rectangle("fill", time * 100, 20, 10, 10)

    gfx.pop()
end

function drawable.sprite(entity)
    local state = entity:ensure(nw.component.sprite_state)
    local state_map = entity:get(nw.component.sprite_state_map) or dict()
    local is_alive = combat.core.is_alive(entity)

    if entity:has(nw.component.health) and not is_alive then
        state = "dead"
    end

    local frame = state_map[state]
    
    gfx.push("all")
    
    gfx.applyTransform(transform.get_with_team(entity))
    nw.drawable.push_state(entity)
    
    if frame then 
        frame:draw("body")
    else
        gfx.rectangle("fill", -10, -20, 20, 20)
    end

    gfx.pop()

    if is_alive then drawable.ai_intent(entity) end
end

local dagger_spray_opt = {
    range = 200,
    num = 9,
    spread = math.pi * 0.25
}

function drawable.dagger_spray(entity)
    local timer = entity:get(nw.component.timer)
    if not timer then return end

    gfx.push("all")
    nw.drawable.push_state(entity)
    nw.drawable.push_transform(entity)
    
    local t = timer and timer:inverse_normalized() or 0
    local alpha = ease.inExpo(t, 1, -1, 1)
    local d = ease.linear(t, 0, dagger_spray_opt.range, 1)
    nw.drawable.push_color(entity, alpha)

    for i = 1, dagger_spray_opt.num do
        local s = dagger_spray_opt.spread
        local r = ease.linear(i - 1, -s / 2, s, dagger_spray_opt.num - 1)
        gfx.push()
        gfx.rotate(r)
        gfx.ellipse("fill", d, 0, 4, 1)
        gfx.pop()
    end
    
    gfx.pop()
end

local card_layout = {
    body = spatial(-25, -75, 50, 75),

}

function drawable.card(entity)
    gfx.push("all")
    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)
    gfx.setColor(0.2, 0.5, 0.1)
    gfx.rectangle("line", card_layout.body:unpack())
    gfx.setColor(1, 1, 1)
    gfx.rectangle("fill", card_layout.body:unpack())
    gfx.pop()
end

return drawable