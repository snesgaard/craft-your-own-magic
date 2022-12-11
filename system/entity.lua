local Base = require "system.base"

local entity = Base()

function entity:destroy(entity) entity:destroy() end

local function noop() end

function entity:spawn_from(parent, func, ...)
    local team = parent:get(nw.component.team)

    return parent:world():entity()
        :set(nw.component.parent, parent.id)
        :set(nw.component.team, team)
        :assemble(func or noop, ...)
end

function entity:spawn(parent)
    return parent:world():entity()
end

return entity.from_ctx
