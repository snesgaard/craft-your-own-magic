local component = {}

function component.number(n) return n end

local ui = {}

local function draw_health(entity, health)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    gfx.translate(0, 10)

    local shape = spatial():expand(40, 6)

    local s = health.value / health.max

    gfx.setColor(1, 0.3, 0.1, 0.25)
    gfx.rectangle("fill", shape:unpack())
    gfx.setColor(1, 0.3, 0.1, 0.25)
    gfx.rectangle("fill", shape.x, shape.y, shape.w * s, shape.h)

    gfx.pop()
end

function ui.draw_health_bar(ecs_world)
    local hp = ecs_world:get_component_table(nw.component.health)

    for id, health in pairs(hp) do
        draw_health(ecs_world:entity(id), health)
    end
end

local function draw_number(entity)
    gfx.push("all")

    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)

    local num = entity:get(component.number)

    gfx.print(num, 0, 0)

    gfx.pop()
end

function ui.draw_numbers(ecs_world)
    local number = ecs_world:get_component_table(component.number)

    for id, _ in pairs(number) do
        draw_number(ecs_world:entity(id))
    end
end

local font = gfx.newFont()

local assemble = {}

function assemble.number(entity, x, y, number, color)
    entity
        :set(component.number, number)
        :set(nw.component.color, color)
        :set(nw.component.timer, 2.0)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.position, x, y)
        :set(nw.component.font, font)
end

local rules = {}

local function spawn_position(entity)
    local x, y, w, h = nw.system.collision().get_bump_hitbox(entity)
    local x = love.math.random(x, x + w)
    local y = love.math.random(y, y + h)
    return vec2(x, y)
end

function rules.on_trigger_effect(ctx, args, ecs_world)
    if not args.info[effect.damage] then return end

    local damage = args.info[effect.damage].damage
    local pos = spawn_position(args.target)
    ecs_world:entity()
        :assemble(assemble.number, pos.x, pos.y, damage, {1, 0.2, 0.1})
end

ui.rules = rules

ui.assemble = assemble

return ui
