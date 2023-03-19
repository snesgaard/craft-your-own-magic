local tween = {}

function tween.update(ecs_world, id, tween_comp, dt)
    if tween_comp:is_done() then return end

    local _, v, dv = tween_comp:update(dt)
    local f = ecs_world:get(nw.component.tween_callback, id)
    if f then f(ecs_world:entity(id), v, dv) end
    
    if tween_comp:is_done() and ecs_world:get(nw.component.die_on_timer_complete, id) then
        nw.system.entity():destroy(ecs_world, id)
    end
end

function tween.spin(ecs_world)
    local tweens = ecs_world:get_component_table(nw.component.tween)

    for _, dt in pairs(ecs_world:get_component_table(nw.component.update)) do
        for id, t in pairs(tweens) do
            tween.update(ecs_world, id, t, dt)
        end
    end
end

function tween.is_done(entity)
    local t = entity:get(nw.component.tween)
    if not t then return true end
    return t:is_done()
end

return tween