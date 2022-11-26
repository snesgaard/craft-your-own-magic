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

local script = {}

function script.attack(ctx, entity)
    local players = Dictionary.map(
        animations.bash,
        function(key, anime)
            return animation.player(anime)
                :on_update(function(value)
                    handle_frame(entity, value.frame)
                end)
        end
    )

    players.anticipation
        :play_in_seconds(0.4)
        :play_once()
        :spin(ctx)
    players.action:play_once():spin(ctx)
    players.recover:play_once():spin(ctx)
end

function script.entry(ctx, entity)
    while ctx:is_alive() do
        script.attack(ctx, entity)
        ctx:yield()
    end
end

function script.idle(ctx, entity)
    local player = animation.player(animations.bash_anticipation)
        :set_speed(0.25)
        :on_update(function(value)
            handle_frame(entity, value.frame)
        end)

    while ctx:is_alive() do
        player:spin_once(ctx)

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
end

return {
    assemble=assemble
}
