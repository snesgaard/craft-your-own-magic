local camera = {}

function camera.push_transform(id)
    local id = id or constant.id.camera

    local w, h = painter.screen_size()
    local p = stack.get(nw.component.position, id)
    if p then gfx.translate(-p.x, -p.y) end
    gfx.translate(w / 2, h / 2)
end

function camera.track(target_id, camera_id)
    local camera_id = camera_id or constant.id.camera

    local p = stack.get(nw.component.position, target_id)
    if not p then return end

    local camera_tracking = stack.ensure(nw.component.camera_tracking, camera_id)
    local c_p = stack.ensure(nw.component.position, camera_id)
    local slack = camera_tracking.slack

    local x = math.clamp(c_p.x, p.x - slack, p.x + slack)
    local y = math.clamp(c_p.y, p.y - slack, p.y + slack)

    stack.set(nw.component.position, camera_id, x, y)
end

return camera