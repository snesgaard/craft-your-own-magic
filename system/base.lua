return function()
    local Base = class()

    function Base.constructor(world)
        return {world=world}
    end

    function Base:emit(...)
        if self.world then self.world:emit(...) end
    end

    function Base.from_ctx(ctx)
        Base.default_instance = Base.default_instance or Base.create()
        if not ctx then return Base.default_instance end
        local world = ctx.world or ctx
        if not world[Base] then world[Base] = Base.create() end
        return world[Base]
    end

    function Base.observables(ctx) return {} end

    function Base.handle_observables() end

    return Base
end
