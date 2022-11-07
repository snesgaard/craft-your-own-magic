local ai = require "ai"

local effect = list(
    {effect.damage, 20}
)

local script = {}

function script.normal(ctx, entity)
    entity:remove(nw.component.effect)

    local should_activate = ctx:listen("collision")
        :filter(function(colinfo) return colinfo.other == entity.id end)
        :filter(function(colinfo)
            return colinfo.ecs_world:get(nw.component.is_actor, colinfo.item)
        end)
        :latest()

    while ctx:is_alive() and not should_activate:peek() do
        ctx:yield()
    end

    return script.activated(ctx, entity)
end

function script.activated(ctx, entity)
    --ai():wait(ctx, 0.5)
    entity:set(nw.component.timer, 0.5)

    local timer_is_done = ctx:listen("timer_completed")
        :filter(function(id) return id == entity.id end)
        :latest()

    while not timer_is_done:peek() and ctx:is_alive() do ctx:yield() end

    entity
        :set(nw.component.effect, effect:unpack())
        :set(nw.component.check_collision_on_update)
        :set(nw.component.trigger_once_pr_entity)

    ai():wait(ctx, 0.5)

    entity
        :remove(nw.component.effect)
        :remove(nw.component.timer)
end

function script.top(ctx, entity)
    while ctx:is_alive() do script.normal(ctx, entity) end
end

local function draw(entity)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)

    if entity:get(nw.component.effect) then
        gfx.setColor(1, 0.2, 0.1)
    elseif entity:get(nw.component.timer) then
        gfx.setColor(1, 0.8, 0.2)
    else
        gfx.setColor(0.2, 1, 0.1)
    end

    local body = entity % nw.component.hitbox
    if not body then return end

    gfx.rectangle("fill", body:unpack())

    gfx.pop()
end

local assemble = {}

function assemble.trap(entity, x, y, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(100, 20), bump_world
        )
        :assemble(nw.system.script().set, script.top)
        :set(nw.component.team, "neutral")
        :set(nw.component.is_effect)
        :set(nw.component.drawable, draw)
end

return {
    assemble = assemble,
    script = script
}
