local slider = {}

local function transform_into_local(entity, x, y)
    local pos = entity:get(nw.component.position)
    if not pos then return x, y end

    return x - pos.x, y - pos.y
end

local function lerp(s, min, max)
    return min * (s - 1) + max * s
end

local function recompute_value_maybe(entity, x, y, min, max)
    local is_down = entity:maybe_get(nw.component.is_down)
    local rect = entity:maybe_get(nw.component.mouse_rect)

    return (is_down + rect)
        :map(function(_, rect)
            local lx, ly = transform_into_local(entity, x, y)
            local sx = math.clamp((lx - rect.x) / rect.w, 0, 1)
            return lerp(sx, min, max)
        end)
        :value_or_default()
end

local function recompute_value(entity, x, y, min, max)
    if not entity:get(nw.component.is_down) then return end
    local rect = entity:get(nw.component.mouse_rect)
    if not rect then return end
    local lx, ly = transform_into_local(entity, x, y)
    local sx = math.clamp((lx - rect.x) / rect.w, 0, 1)
    return lerp(sx, min, max)
end

local function handle_mouse_moved(ecs_world, mousemoved)
    local sliders = ecs_world:get_component_table(nw.component.slider)

    for id, slider_data in pairs(sliders) do
        local next_value = recompute_value_maybe(
            ecs_world:entity(id), mousemoved.x, mousemoved.y,
            slider_data.min, slider_data.max
        )
        if next_value then
            ecs_world:set(nw.component.slider, id, next_value, slider_data.min, slider_data.max)
        end
    end
end

function slider.spin(ecs_world)
    local mousemoved = ecs_world:get_component_table(nw.component.mousemoved)
    
    for _, m in pairs(mousemoved) do
        handle_mouse_moved(ecs_world, m)
    end
end

function slider.draw_widget(entity)
    local slider = entity % nw.component.slider
    local rect = entity % nw.component.mouse_rect
    if not slider or not rect then return end

    gfx.push("all")
    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)
    nw.drawable.push_color(entity)
    
    gfx.rectangle("line", rect.x, rect.y, rect.w, rect.h)
    local s = (slider.value - slider.min) / (slider.max - slider.min)
    gfx.rectangle("fill", rect.x, rect.y, rect.w * s, rect.h)

    gfx.pop()
end

return slider