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

return drawable