local AI = class()

function AI.create(world)
    return setmetatable({world=world}, AI)
end

function AI.move_to(entity, target, step)
    local pos = entity:get(nw.component.position)
    if not pos then return end

    local diff = target - pos
    local l = diff:length()
    if l <= step then
        return target, true
    else
        return pos + diff * step / l, false
    end
end

function ai:wait(ctx, duration)
    local timer = nw.component.timer(duration)
    local update = ctx:listen("update"):collect()

    while ctx:is_alive() and not timer:done() do
        update:pop():foreach(function(dt) timer:update(dt) end)
        ctx:yield()
    end
end

return declare_world_interface(AI.create)
