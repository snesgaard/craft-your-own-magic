local jump = {}

function jump.drawable(id)
    local t, d = timer.get(id)
    if not t then return end

    gfx.push("all")

    nw.drawable.push_transform(id)

    local r = ease.linear(t, 0, 50, d)
    local alpha = ease.inQuad(t, 1, -1, d)
    gfx.setColor(1, 1, 1, alpha)
    gfx.rectangle("fill", spatial():expand(r, 5):unpack())

    gfx.pop()
end

function jump.spawn(x, y)
    return stack.assemble(
        {
            {nw.component.position, x, y},
            {nw.component.drawable, jump.drawable},
            {nw.component.timer, 0.2},
            {nw.component.die_on_timer_done},
            {nw.component.layer, 1000}
        },
        nw.ecs.id.strong("jumpsfx")
    )
end

local sfx = {}

function sfx.spin()
    for _, id, pos in event.view("jump") do
        jump.spawn(pos.x, pos.y)
    end
end

return sfx