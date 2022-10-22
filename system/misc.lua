local misc = {}

function misc.destroy(ctx, id, ecs_world)
    ecs_world:destroy(id)
end

return misc
