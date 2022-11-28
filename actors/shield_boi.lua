local animations = {
    walk = animation.from_aseprite("art/characters", "shield_boi/walk"),
    bash = {
        anticipation = animation.from_aseprite(
            "art/characters", "shield_boi/bash:anticipation"
        ),
        action = animation.from_aseprite(
            "art/characters", "shield_boi/bash:action"
        ),
        recover = animation.from_aseprite(
            "art/characters", "shield_boi/bash:recover"
        )
    }
}

local function handle_frame(entity, frame)
    entity:set(nw.component.frame, frame)
end

local function effect_from_slice_data(slice_data)
    if not slice_data then return end

    local effects = list()

    if slice_data.damage then
        table.insert(effects, {effect.damage, slice_data.damage})
    end

    return effects:unpack()
end

local function create_hitbox(entity, slice, anchor, slice_data)
    local pos = entity:ensure(nw.component.position)
    local bump_world = entity:get(nw.component.bump_world)
    local team = entity:get(nw.component.team)

    return entity:world():entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            pos.x, pos.y, slice:move(-anchor.x, -anchor.y), bump_world
        )
        :set(nw.component.effect, effect_from_slice_data(slice_data))
        :set(nw.component.is_effect)
        :set(nw.component.team, team)
        :set(nw.component.check_collision_on_update)
        :set(nw.component.trigger_once_pr_entity)

end

local function handle_slices(entity, frame, prev_frame)
    if frame == prev_frame then return end
    local slices = entity:ensure(nw.component.slices)

    local anchor = frame.slices.body:centerbottom()

    for _, s in pairs(slices) do s:destroy() end

    for name, slice in pairs(frame.slices) do
        slices[name] = create_hitbox(entity, slice, anchor, frame.slice_data[name])
    end
end

local script = {}

function script.attack(ctx, entity)
    local players = Dictionary.map(
        animations.bash,
        function(key, anime)
            return animation.player(anime)
                :on_update(function(value, prev_value)
                    handle_frame(entity, value.frame)
                    handle_slices(entity, value.frame, prev_value.frame)
                end)
        end
    )

    players.anticipation
        :play_in_seconds(0.4)
        :play_once()
        :spin(ctx)
    players.action
        :play_once()
        :spin(ctx)
    players.recover
        :play_in_seconds(0.4)
        :play_once()
        :spin(ctx)
end

function script.move(ctx, entity, dir)
    local dir = dir or 1
    local motion = animation.animation()
        :timeline(
            "motion", list({value=0, time=0}, {value=50, time=1.5}),
            ease.inOutQuad
        )
    local player = animation.player(motion)
        :play_once()
        :on_update(function(value, prev_value)
            local dv = value.motion - (prev_value.motion or 0)
            nw.system.collision(ctx):move(entity, dv * dir, 0)
        end)
    local walk_player = animation.player(animations.walk)
        :on_update(function(value)
            handle_frame(entity, value.frame)
        end)

    while ctx:is_alive() and not player:done() do
        player:spin_once(ctx)
        walk_player:spin_once(ctx)
        ctx:yield()
    end

end

function script.decision(ctx, entity)
    local rng = love.math.random()
    if rng < 0.2 then
        script.move(ctx, entity, -1)
    elseif rng < 0.6 then
        script.move(ctx, entity, 1)
    else
        script.attack(ctx, entity)
    end
end

function script.entry(ctx, entity)
    while ctx:is_alive() do
        script.decision(ctx, entity)
        ctx:yield()
    end
end

local body = nw.component.hitbox(16, 32)

local function assemble(entity, x, y, bump_world)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, body, bump_world
        )
        :assemble(nw.system.script().set, script.entry)
        :set(nw.component.drawable, nw.drawable.frame)
        :set(nw.component.health, 20)
end

return {
    assemble=assemble
}
