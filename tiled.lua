local sti = nw.third.sti

local tiled = {}

local function load_tilelayer(index, layer)
    if layer.type ~= "tilelayer" then return end

    for _, chunk in ipairs(layer.chunks) do
    
        chunk.ids = list()
        for y, row in pairs(chunk.data) do
            for x, tile in pairs(row) do
                local id = nw.ecs.id.weak("tile")
                collision.register(id, spatial(0, 0, tile.width, tile.height))
                collision.warp_to(id, (chunk.x + x - 1) * tile.width, (chunk.y + y - 1) * tile.height)
                table.insert(chunk.ids, id)
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

local function unload_tilelayer(index, layer)
    if layer.type ~= "tilelayer" then return end

    stack.destroy(layer)

    for _, chunk in ipairs(layer.chunks) do
        for _, id in ipairs(chunk.ids or list()) do stack.destroy(id) end
        chunk.ids = nil
    end
end

local function load_objectgroup(index, layer)
    if layer.type ~= "objectgroup" then return end

    layer.ids = list()
    for _, object in ipairs(layer.objects) do
        local id = tiled.load_object(object, index, layer)
        if id then table.insert(layer.ids, id) end
    end
end

local function unload_objectgroup(index, layer)
    if layer.type ~= "objectgroup" then return end

    for _, id in ipairs(layer.ids or list()) do stack.destroy(id) end
    layer.ids = nil
end

function tiled.load_object(object, index, layer)
    local f = tiled.type_loader[object.type]
    if not f then
        print("No loader for type", object.type)
        return
    end
    return f(object, index, layer)
end

local type_loader = {}
tiled.type_loader = type_loader

function type_loader.foobar(object, index, layer)
    local id = object.id

    local x, h, w, h = object.x, object.y, object.width, object.height
    local w, h = 16, 16
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, object.x, object.y)

    stack.assemble(
        {
            {nw.component.gravity, 0, 100},
            {nw.component.player_controlled},
            {nw.component.camera_should_track},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.layer, index}
        },
        id
    )

    return id
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