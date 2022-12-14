local Base = require "system.base"

local entity = Base()

function entity:destroy(entity)
    self:emit("on_destroyed", entity)
    entity:destroy()
end

local function noop() end

function entity:spawn_from(parent, func, ...)
    local team = parent:get(nw.component.team)

    local child = self:spawn(parent:world())
        :set(nw.component.parent, parent.id)
        :set(nw.component.team, team)
        :assemble(func or noop, ...)

    local info = {
        child = child,
        parent = parent,
        func = func,
        args = {...}
    }

    self:emit("on_spawned_from", info)

    return child
end

function entity:spawn(ecs_world, id)
    local child = ecs_world:entity(id)
    self:emit("on_spawned", child, parent)
    return child
end


return entity.from_ctx
