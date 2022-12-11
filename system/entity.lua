local Base = require "system.base"

local entity = Base()

function entity:destroy(entity) entity:destroy() end

function entity:spawn_from(parent, ...)
    local team = parent:get(nw.component.team)

    return entity:world():entity()
        :set(nw.component.parent, parent.id)
        :set(nw.component.team, team)
        :assemble(...)
end

return entity.from_ctx
