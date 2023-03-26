local deck = {}

function deck.setup_from_deck(ecs_world, id)
    local deck = ecs_world:ensure(nw.component.deck, id)
    local card_state = ecs_world:ensure(nw.component.player_card_state, id)

    card_state.draw = deck:shuffle()
    card_state.discard = list()
    card_state.hand = list()
    card_state.incant = dict()
    card_state.executed = list()
end

function deck.draw_card_from_deck(ecs_world, id)
    local state = ecs_world:get(nw.component.player_card_state, id)
    if not state then return end

    local head = state.draw:head()

    if not head then
        if state.discard:size() == 0 then
            return 
        else
            deck.shuffle_discard_into_draw(ecs_world, id)
            return deck.draw_card_from_deck(ecs_world, id)
        end
    end

    state.draw = state.draw:body()
    state.hand = state.hand:insert(head)

    nw.system.entity():emit(ecs_world, event.on_card_draw, id, head)

    return head
end

function deck.shuffle_draw(ecs_world, id)
    local state = ecs_world:get(nw.component.player_card_state, id)
    if not state then return end

    local before = state.draw
    local after = before:shuffle()

    state.draw = after

    nw.system.entity():emit(ecs_world, event.on_shuffle_draw, id, before, after)
    return after
end

function deck.move_discard_into_draw(ecs_world, id)
    local state = ecs_world:get(nw.component.player_card_state, id)
    if not state then return end

    state.draw = state.draw + state.discard
    state.discard = list()
end

return deck