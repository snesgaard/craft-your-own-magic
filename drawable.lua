local drawable = {}

function drawable.tilelayer(id)
    local layer = stack.get(nw.component.tilelayer, id)
    if not layer then return end

    gfx.push("all")
    
    nw.drawable.push_transform(id)
    nw.drawable.push_state(id)
    layer:draw()

    gfx.pop()
end

function drawable.bump_body(id)
    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then return end

    gfx.push("all")
    nw.drawable.push_state(id)
    gfx.rectangle("fill", x, y, w, h)
    gfx.pop()
end

function drawable.switch(id)
    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then return end

    gfx.push("all")
    nw.drawable.push_state(id)
    if stack.get(nw.component.switch, id) then
        gfx.setColor(0.1, 0.8, 0.2)
    else
        gfx.setColor(0.8, 0.2, 0.1)
    end
    gfx.rectangle("fill", x, y, w, h)
    gfx.pop()
end

function drawable.frame(id)
    local f = stack.get(nw.component.frame, id)
    if not f then return end

    gfx.push("all")

    nw.drawable.push_transform(id)
    nw.drawable.push_state(id)

    local state = stack.get(nw.component.puppet_state, id)
    if state and state.name == "charge" and puppet_control.boxer.charge.is_done(state) then
        gfx.setColor(0, 0, 1)
    end

    f:draw("body")

    gfx.pop()
end

return drawable