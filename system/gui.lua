local numbers = {}

function numbers.spawn(x, y, number)
    local id = nw.ecs.id.strong("number")

    stack.assemble(
        {
            {nw.component.position, x, y},
            {nw.component.text, tostring(number)},
            {nw.component.text_opt, {font=painter.font(32), align="center", valign="center"}},
            {nw.component.drawable, nw.drawable.text},
            {nw.component.gui_area, spatial():expand(20, 20)},
            {nw.component.timer, 1.0},
            {nw.component.die_on_timer_done},
            {nw.component.layer, 1000}
        },
        id
    )
end

function numbers.position(id)
    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then
        local pos = stack.get(nw.component.position, id) or vec2()
        return pos.x, pos.y
    end

    local x = love.math.random(x, x + w)
    local y = love.math.random(y, y + h)

    return x, y
end

function numbers.spin()
    for _, info in event.view("damage") do
        local x, y = numbers.position(info.target)
        numbers.spawn(x, y, info.damage)
    end
end

local health_bar = {}

function health_bar.draw_bar(health)
    if not health then return end

    gfx.push("all")
    local area = spatial(5, 5, 50, 50)
    gfx.setColor(0.8, 0.3, 0.2)
    gfx.rectangle("fill", area:unpack())
    gfx.setColor(1, 1, 1)
    painter.draw_text(
        tostring(health), area, {align="center", valign="center", font=painter.font(32 * 5)}
    )
    gfx.pop()

    return true
end

function health_bar.draw()
    for id, _ in stack.view_table(nw.component.player_controlled) do
        local hp = stack.get(nw.component.health, id)
        if health_bar.draw_bar(hp.value) then return end
    end
end

local gui = {
    health_bar = health_bar
}

function gui.spin()
    numbers.spin()
end

return gui