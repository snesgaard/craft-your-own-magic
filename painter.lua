local painter = {}

painter.scale = 4

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

    for _, entity in ipairs(entities) do
        local f = entity:get(nw.component.drawable)
        gfx.push("all")
        f(entity)
        gfx.pop()
    end
end

return painter
