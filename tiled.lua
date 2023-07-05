local sti = nw.third.sti

local tiled = {}

tiled.project_path = "art/craft.tiled-project"

tiled.project_object_properties = {}

function tiled.load_project(p)
    local f = love.filesystem.read(p or tiled.project_path)
    local data = nw.third.json.decode(f)
    for _, prop_type in ipairs(data.propertyTypes or {}) do
        local properties = dict()
        for _, m in ipairs(prop_type.members) do
            properties[m.name] = m.value 
        end

        if List.argfind(prop_type.useAs, "object") then
            tiled.project_object_properties[prop_type.name] = properties
        end
    end
end

local function load_tilelayer(index, layer)
    if layer.type ~= "tilelayer" then return end

    for _, chunk in ipairs(layer.chunks) do
    
        chunk.ids = list()
        for y, row in pairs(chunk.data) do
            for x, tile in pairs(row) do
                local id = nw.ecs.id.weak("tile")
                collision.register(id, spatial(0, 0, tile.width, tile.height))
                collision.warp_to(id, (chunk.x + x - 1) * tile.width, (chunk.y + y - 1) * tile.height)
                stack.set(nw.component.is_terrain, id)
                table.insert(chunk.ids, id)
            end
        end
    end

    stack.assemble(
        {
            {nw.component.layer, index},
            {nw.component.tilelayer, layer},
            {nw.component.drawable, nw.drawable.tilelayer},
            {nw.component.hidden, not layer.visible},
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
    if not f or not object.visible then
        print("No loader for type", object.type)
        return
    end
    return f(object, index, layer)
end

local function hitbox_from_body(idle)
    local slice = idle.frames:head().slices.body
    local w, h = slice.w, slice.h
    return spatial(math.floor(-w / 2), -h, w, h)
end

local type_loader = {}
tiled.type_loader = type_loader

function type_loader.mc_basic(object, index, layer)
    local id = nw.ecs.id.strong("foobar")

    local x, h, w, h = object.x, object.y, object.width, object.height
    local w, h = 8, 28
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, object.x, object.y)

    local sprite_state_map = dict{
        idle = Video.from_atlas("art/characters", "mc/idle"):speed(0.5):loop(),
        walk = Video.from_atlas("art/characters", "mc/run"):loop(),
        dash = Video.from_atlas("art/characters", "mc/dash"):speed(2):loop(),
        bash = Video.from_atlas("art/characters", "mc/attack"):once(),
        ascend = Video.from_atlas("art/characters", "mc/ascend"):loop(),
        descend = Video.from_atlas("art/characters", "mc/descend"):loop(),
        cast = Video.from_atlas("art/characters", "mc/cast"):once()
    }

    stack.assemble(
        {
            {nw.component.gravity},
            {nw.component.player_controlled},
            {nw.component.camera_should_track},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.puppet_state_map, sprite_state_map},  
            {nw.component.puppet_state, "idle"},
            {nw.component.script("player")},
            {nw.component.puppet("player")},
            {nw.component.layer, index}
        },
        id
    )

    return id
end

function type_loader.generic(object, index, layer)
    local id = nw.ecs.id.strong("generic")

    local pp = tiled.project_object_properties.generic or dict()
    local p = Dictionary.fuse(object.properties, pp)

    if p.collision then
        local x, h, w, h = object.x, object.y, object.width, object.height
        collision.register(id, spatial(0, 0, w, h))
    end

    collision.warp_to(id, object.x, object.y)

    stack.assemble(tiled.assemble_from_properties(p), id)

    return id
end

function type_loader.edge_patrol(object, index, layer)
    local id = nw.ecs.id.strong("edge_patorl")

    local p = object.properties
    
    local w, h  = 10, 5
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, object.x, object.y)

    local sprite_state_map = dict{
        idle = Video.from_atlas("art/characters", "mc-boxer/idle"):loop(),
        walk = Video.from_atlas("art/characters", "mc-boxer/run"):loop(),
        charge = Video.from_atlas("art/characters", "mc-boxer/charge"):loop(),
        fly_punch_h = Video.from_atlas("art/characters", "mc-boxer/fly_punch_h"):loop(),
        fly_punch_v = Video.from_atlas("art/characters", "mc-boxer/fly_punch_v"):loop(),
        ascend = Video.from_atlas("art/characters", "mc-boxer/idle"):loop(),
        descend = Video.from_atlas("art/characters", "mc-boxer/idle"):loop(),
        punch_a = Video.from_atlas("art/characters", "mc-boxer/punch_a"):speed(0.5):once(),
        punch_b = Video.from_atlas("art/characters", "mc-boxer/punch_b"):speed(0.5):once(),
    }

    local c = list(
        {nw.component.drawable, nw.drawable.bump_body},
        {nw.component.gravity},
        {nw.component.script("edge_patrol")},
        {nw.component.drawable, nw.drawable.frame},
        {nw.component.puppet("boxer-player")},
        {nw.component.puppet_state_map, sprite_state_map}
        --{nw.component.move_speed, 30}
    )
    stack.assemble(c, id)

    return id
end

function type_loader.mc_boxer(object, index, layer)
    local id = nw.ecs.id.strong("mc-boxer")

    local x, h, w, h = object.x, object.y, object.width, object.height
    local w, h = 8, 28
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, object.x, object.y)

    local sprite_state_map = dict{
        idle = Video.from_atlas("art/characters", "mc-boxer/idle"):loop(),
        walk = Video.from_atlas("art/characters", "mc-boxer/run"):loop(),
        charge = Video.from_atlas("art/characters", "mc-boxer/charge"):loop(),
        fly_punch_h = Video.from_atlas("art/characters", "mc-boxer/fly_punch_h"):loop(),
        fly_punch_v = Video.from_atlas("art/characters", "mc-boxer/fly_punch_v"):loop(),
        ascend = Video.from_atlas("art/characters", "mc-boxer/idle"):loop(),
        descend = Video.from_atlas("art/characters", "mc-boxer/idle"):loop(),
        punch_a = Video.from_atlas("art/characters", "mc-boxer/punch_a"):speed(0.5):once(),
        punch_b = Video.from_atlas("art/characters", "mc-boxer/punch_b"):speed(0.5):once(),
    }

    stack.assemble(
        {
            {nw.component.gravity},
            {nw.component.player_controlled},
            {nw.component.camera_should_track},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.puppet_state_map, sprite_state_map},  
            {nw.component.puppet_state, "idle"},
            {nw.component.script("boxer-player")},
            {nw.component.puppet("boxer-player")},
            {nw.component.layer, index},
        },
        id
    )

    return id
end

function type_loader.gobbo(object, index, layer)
    local id = object.id
    local x, y = object.x + object.width / 2, object.y + object.height
    local w, h = 8, 28
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, x, y)

    local sprite_state_map = dict{
        idle = Video.from_atlas("art/characters", "gobbo/idle"):loop(),
        walk = Video.from_atlas("art/characters", "gobbo/run"):loop(),
        ascend = Video.from_atlas("art/characters", "gobbo/ascend"):loop(),
        descend = Video.from_atlas("art/characters", "gobbo/descend"):loop(),
        hit = Video.from_atlas("art/characters", "gobbo/hit"):once(),
        dash = Video.from_atlas("art/characters", "gobbo/dash")
    }

    stack.assemble(
        {
            {nw.component.gravity},
            {nw.component.player_controlled},
            {nw.component.camera_should_track},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.puppet_state_map, sprite_state_map},
            {nw.component.puppet_state, "idle"},
            {nw.component.script("boxer-player")},
            {nw.component.layer, index},
            {nw.component.move_speed, 100},
            {nw.component.health, 20}
        },
        id
    )

    return id
end

function type_loader.bonk_bot(object, index, layer)
    local id = object.id
    
    local x, y = object.x + object.width / 2, object.y + object.height
    local w, h = 8, 28
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, x, y)

    local sprite_state_map = {
        idle = get_video("bonk_bot/idle"):loop(),
        hit = get_video("bonk_bot/hit"):once()
    }

    stack.assemble(
        {
            {nw.component.gravity},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.puppet_state_map, sprite_state_map},
            {nw.component.puppet_state, "idle"},
            {nw.component.layer, index},
            {nw.component.move_speed, 35},
            {nw.component.health, 10},
            {nw.component.debug},
            {nw.component.script("bonk_bot")}
        },
        id
    )

    return id
end

function type_loader.shoot_bot(object, index, layer)
    local id = object.id

    local x, y = object.x, object.y
    local w, h = 8, 28
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, x, y)

    local sprite_state_map = {
        idle = get_video("shoot_bot/idle"):loop(),
        shoot = get_video("shoot_bot/shoot"):once()
    }

    stack.assemble(
        {
            {nw.component.gravity},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.puppet_state_map, sprite_state_map},
            {nw.component.puppet_state, "idle"},
            {nw.component.layer, index},
            {nw.component.move_speed, 35},
            {nw.component.script("shoot_bot")}
        },
        id
    )

    return id
end

function type_loader.cloak(object, index, layer)
    local id = object.id

    local sprite_state_map = {
        idle = get_video("cloak/idle"):loop(),
        walk = get_video("cloak/run"):loop(),
        prepare_jump_hit = get_video("cloak/prepare_jump_hit"):loop(),
        action_jump_hit = get_video("cloak/action_jump_hit"):once(),
        recover_jump_hit = get_video("cloak/recover_jump_hit"):loop(),
        prepare_hit = get_video("cloak/prepare_hit"):loop(),
        action_hit = get_video("cloak/action_hit"):once(),
        recover_hit = get_video("cloak/recover_hit"):loop(),
    }

    collision.register(id, hitbox_from_body(sprite_state_map.idle))
    collision.warp_to(id, object.x, object.y)

    stack.assemble(
        {
            {nw.component.gravity},
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.puppet_state_map, sprite_state_map},
            {nw.component.puppet_state, "idle"},
            {nw.component.layer, index},
            {nw.component.move_speed, 45},
            {nw.component.script("cloak")},
            {nw.component.health, 15}
        },
        id
    )

    return id
end

function type_loader.switch(object, index, layer)
    local id = object.id

    local x, h, w, h = object.x, object.y, object.width, object.height
    local w, h = 16, 16
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, object.x, object.y)

    stack.assemble(
        {
            {nw.component.is_ghost},
            {nw.component.drawable, nw.drawable.switch},
            {nw.component.switch, false}
        },
        id
    )
    stack.assemble(tiled.assemble_from_properties(object.properties), id)

    return id
end

function type_loader.door(object, index, layer)
    local id = object.id

    local x, h, w, h = object.x, object.y, math.round(object.width), math.round(object.height)
    collision.register(id, spatial(-w / 2, -h, w, h))
    collision.warp_to(id, object.x + w / 2, object.y + h)

    stack.assemble(
        {
            {nw.component.drawable, nw.drawable.bump_body},
            {nw.component.is_terrain}
        },
        id
    )
    stack.assemble(tiled.assemble_from_properties(object.properties), id)

    return id
end

function tiled.assemble_from_properties(properties)
    local c = list()
    local p = properties
    if not p then return c end

    if p.drawable then table.insert(c, {nw.component.drawable, nw.drawable[p.drawable]}) end
    if p.ghost then table.insert(c, {nw.component.is_ghost}) end
    if p.breakable then table.insert(c, {nw.component.breakable}) end
    if p.breaker then table.insert(c, {nw.component.breaker}) end
    if p.damage then table.insert(c, {nw.component.damage, p.damage}) end
    if p.script then table.insert(c, {nw.component.script(p.script)}) end
    if p.target then table.insert(c, {nw.component.target, p.target.id}) end
    if p.terrain then table.insert(c, {nw.component.is_terrain}) end
    if p.hurtbox then table.insert(c, {nw.component.hurtbox}) end
    if p.shoot then table.insert(c, {nw.component.shoot, p.shoot}) end

    return c
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

tiled.load_project()

return tiled