local sti = nw.third.sti

local tiled = {}

local function load_tilelayer(index, layer)
    if layer.type ~= "tilelayer" then return end

    for _, chunk in ipairs(layer.chunks) do
        for y, row in pairs(chunk.data) do
            for x, tile in pairs(row) do
                local id = nw.ecs.id.weak("tile")
                local pos = vec2(
                    (chunk.x + x - 1) * tile.width, (chunk.y + y - 1) * tile.height
                )

                collision.register(id, spatial(0, 0, tile.width, tile.height))
                collision.warp_to(id, pos.x, pos.y)
            end
        end
    end

    stack.assemble(
        {
            {nw.component.layer, index},
            {nw.component.tilelayer, layer},
            {nw.component.drawable, nw.drawable.tilelayer},
            {nw.component.hidden, not layer.visible}
        },
        layer
    )
end

local function load_objectgroup(index, layer)
    if layer.type ~= "objectgroup" then return end

    for _, object in ipairs(layer.objects) do
        tiled.load_object(object, index, layer)
    end
end

function tiled.load_object(object, index, layer)
    --print("load", dict(object))
end

function tiled.load(path)
    stack.reset()

    local map = sti(path)

    for index, layer in ipairs(map.layers) do
        load_tilelayer(index, layer)
        load_objectgroup(index, layer)
    end

    return map
end

function tiled.draw(map)
    for _, layer in ipairs(map.layers) do layer:draw() end
end

local function find_object_in_layer(layer, name)
    if layer.type ~= "objectgroup" then return end

    for _, object in ipairs(layer.objects) do
        if object.name == name then return object end
    end
end

function tiled.object(map, name)
    for _, layer in ipairs(map.layers) do
        local object = find_object_in_layer(layer, name)
        if object then return object end
    end
end

return tiled