local transform = {}

function transform.position(entity)
    local p = entity:get(nw.component.position)
    if not p then return 0, 0 end
    return p.x, p.y
end

function transform.scale(entity)
    local mirror = entity:get(nw.component.mirror)
    if mirror then
        return -1, 1
    else
        return 1, 1
    end
end

function transform.scale_with_team(entity)
    local sx, sy = transform.scale(entity)
    if entity:get(nw.component.enemy_team) then
        return -sx, sy
    else
        return sx, sy
    end
end

function transform.get(entity)
    local x, y = transform.position(entity)
    local r = 0
    local sx, sy = transform.scale(entity)
    return love.math.newTransform(x, y, r, sx, sy)
end

function transform.get_with_team(entity)
    local x, y = transform.position(entity)
    local r = 0
    local sx, sy = transform.scale_with_team(entity)
    return love.math.newTransform(x, y, r, sx, sy)
end

return transform