local component = {}

function component.animated_action(func, ...)
    return {
        func = func,
        args = {...}
    }
end

local action_animation = {}

action_animation.parent_id = "__action_animation__"

function action_animation.clean(ecs_world, id)
    local children = nw.system.parent().get_children(ecs_world:entity(id))

    for child_id, _ in pairs(children) do
        action_animation.clean(ecs_world, child_id)
    end
    ecs_world:destroy(id)
end

function action_animation.spin_once(ecs_world, id)
    local animation = ecs_world:get(component.animated_action, id)
    if not animation then return true end

    return animation.func(ecs_world, id, unpack(animation.args))
end

function action_animation.spin(ecs_world)
    local animations = nw.system.parent().get_children_in_order(
        ecs_world:entity(action_animation.parent_id)
    )
        
    for _, id in ipairs(animations) do
        if not action_animation.spin_once(ecs_world, id) then return false end
        action_animation.clean(ecs_world, id)
    end

    return true
end

function action_animation.empty(ecs_world)
   return nw.system.parent().get_children(ecs_world:entity(action_animation.parent_id)):empty()
end

function action_animation.is_done(ecs_world, id)
    local a = ecs_world:get(component.animated_action, id)
    return not a
end

function action_animation.submit(ecs_world, func, ...)
    return ecs_world:entity()
        :assemble(nw.system.parent().set_parent, ecs_world:entity(action_animation.parent_id))
        :set(component.animated_action, func, ...)

end

return action_animation