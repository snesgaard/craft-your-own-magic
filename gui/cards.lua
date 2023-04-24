local cards = {}

cards.component = {}

function cards.component.title(t) return t end

function cards.component.description(d) return d end

function cards.component.card_data(data) return data end

function cards.component.hand_index(index) return index end

function cards.component.move_card_to(x, y) return vec2(x, y) end

local card_motion_system = {}

function card_motion_system.spin_once(ecs_world, id, move_to, dt)
    local entity = ecs_world:entity(id)
    local pos = entity:ensure(nw.component.position)
    local dir = move_to - pos
    local l = dir:length()
    local speed = 400
    local step = speed * dt
    if l <= step then
        pos.x = move_to.x
        pos.y = move_to.y
    else
        pos.x = pos.x + dir.x * step / l
        pos.y = pos.y + dir.y * step / l
    end
end

function card_motion_system.spin(ecs_world)
    for _, dt in pairs(ecs_world:get_component_table(nw.component.update)) do
        local cb = ecs_world:get_component_table(cards.component.move_card_to)
        for id, move_to in pairs(cb) do
            card_motion_system.spin_once(ecs_world, id, move_to, dt)
        end
    end
end

-------

function cards.index_to_norm(index, size)
    return 0.5 + ease.linear(index - 1, -0.1, 0.2, size - 1)
end

function cards.on_card_draw(ecs_world, event)
    ecs_world:entity()
        :set(nw.component.drawable, nw.drawable.card)
        :set(nw.component.position, painter.norm_to_real(-0.25, 1.15))
        :set(nw.component.layer, 1000)
        :set(cards.component.hand_index, event.index)
end

function cards.on_card_play(ecs_world, event)

end

function cards.navigate_cards_in_hand(ecs_world)
    local card_state = ecs_world:ensure(nw.component.player_card_state, "player")
    local hand_size = card_state.hand:size()

    for id, index in pairs(ecs_world:get_component_table(cards.component.hand_index)) do
        local move_to = ecs_world:ensure(cards.component.move_card_to, id)
        local nx = cards.index_to_norm(index, hand_size)
        move_to.x, move_to.y = painter.norm_to_real(nx, 1.15)
    end
end

function cards.spin(ecs_world)
    for _, event in pairs(ecs_world:get_component_table(event.on_card_draw)) do
        cards.on_card_draw(ecs_world, event)
    end

    cards.navigate_cards_in_hand(ecs_world)
    card_motion_system.spin(ecs_world)
end

return cards