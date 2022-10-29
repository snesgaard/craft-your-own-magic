local transform = {}

function transform.velocity(entity, v)
    if entity:get(nw.component.mirror) then
        return vec2(-v.x, v.y)
    else
        return v
    end
end

function transform.position(entity, v)
    local out = vec2(v.x, v.y)
    if entity:get(nw.component.mirror) then
        out.x = -out.x
    end

    local pos = entity:get(nw.component.position)
    if pos then
        out.x = out.x + pos.x
        out.y = out.y + pos.y
    end

    return out
end

function transform.shape(entity, shape)
    local out = shape
    if entity:get(nw.component.mirror) then
        out = out:scale(-1, 1)
    end

    local pos = entity:get(nw.component.pos)
    if pos then out = out:move(pos.x, pos.y) end

    return out:sanitize()
end

return transform
