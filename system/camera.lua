local camera = {}

function camera.push_transform(id)
    local id = id or constant.id.camera

    local w, h = painter.screen_size()
    local p = stack.get(nw.component.position, id)
    if p then gfx.translate(p.x, p.y) end
    gfx.translate(w / 2, h / 2)
end

return camera