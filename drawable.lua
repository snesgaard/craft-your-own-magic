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

return drawable