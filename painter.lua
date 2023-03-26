local painter = {}

painter.scale = 4

function painter.norm_to_real(nx, ny)
    local w, h = gfx.getWidth(), gfx.getHeight()
    local s = painter.scale

    return (nx or 0) * w / s, (ny or 0) * h / s
end

painter.default_font = {
    path = "art/font/m5x7.ttf",
}

function painter.font(size)
    local df = painter.default_font
    df[size] = df[size] or gfx.newFont(df.path, size, "mono")
    return df[size]
end

local layers = {
    background = -1,
    player = 1,
    effects = 2
}

local function sort_by_position(a, b)
    local pos_a = a:ensure(nw.component.position)
    local pos_b = b:ensure(nw.component.position)

    local dx = pos_a.x - pos_b.x

    if math.abs(dx) > 1 then return pos_a.x < pos_b.x end

    return pos_a.y < pos_b.y
end

local function sort_by_layer(a, b)
    local layer_a = a:ensure(nw.component.layer)
    local layer_b = b:ensure(nw.component.layer)

    if layer_a ~= layer_b then return layer_a < layer_b end

    return sort_by_position(a, b)
end

local function get_entity(id, ecs_world) return ecs_world:entity(id) end

function painter.draw(ecs_world)
    local drawables = ecs_world:get_component_table(nw.component.drawable)
    local entities = drawables
        :keys()
        :map(get_entity, ecs_world)
        :sort(sort_by_layer)
    
    gfx.push()
    gfx.scale(painter.scale, painter.scale)

    painter.draw_text(
        "fooobar baz", spatial(50, 50, 50, 50),
        {
            align="center", valign="center"
        }
    )

    for _, entity in ipairs(entities) do
        local f = entity:get(nw.component.drawable)
        gfx.push("all")
        f(entity)
        gfx.pop()
    end

    gfx.pop()
end

local function compute_valign(text, font, w, h, scale, valign)
    local _, segs = font:getWrap(text, w / scale)
    local th = #segs * font:getHeight() * scale
    if valign == "center" then
        return (h  - th) * 0.5
    elseif valign == "bottom" then
        return th
    end

    return 0
end

local DEFAULT_OPT = {
    align = "left",
    valign = "top",
    scale = 4
}

function painter.draw_text(text, area, opt)
    local opt = opt or DEFAULT_OPT
    local align = opt.align or DEFAULT_OPT.align
    local valign = opt.valign or DEFAULT_OPT.valign
    local s = opt.scale or DEFAULT_OPT.scale
    local font = opt.font or gfx.getFont()
    local dy = compute_valign(text, font, area.w, area.h, 1.0 / s, valign)
    gfx.printf(
        text, font, area.x, area.y + dy,
        area.w * s, align,
        0, 1.0 / s, 1.0 / s
    )
end

return painter
