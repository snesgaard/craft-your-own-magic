local combat = require "combat"

local ai = {}

function ai.find_target(ecs_world, user, target_type, same)
    local team = combat.target.get_team(ecs_world, user, same)

    if target_type == "self" then
        return user
    elseif target_type == "single" then
        return team:head()
    elseif target_type == "all" then
        return team:unpack()
    end
end

function ai.process_action(ecs_world, id, action)
    local data = ecs_world:entity(id)
    local target_type = action.target or "single"
    local targets = data:ensure(ai.find_target, ecs_world, user, target_type)
    data:ensure(action.submit, ecs_world, action.run, action, targets:unpack())
    return action.is_done(ecs_world, id)
end

function ai.advance_action_deck(ecs_world, id)
    local user = ecs_world:entity(id)
    local ai = user:ensure(nw.component.ai_state)
    ai.discard = ai.discard:insert(ai.draw:head())
    ai.draw = ai.draw:body()

    if ai.draw:empty() then
        ai.draw = ai.discard
        ai.discard = list()
    end

    return ai.discard
end

function ai.get_next_action(ecs_world, id)
    local user = ecs_world:entity(id)
    local ai = user:ensure(nw.component.ai_state)
    return ai.discard:head()
end

function ai.prepare_next_action(ecs_world, id)
    ai.advance_action_deck(ecs_world, id)
    return ai.get_next_action(ecs_world, id)
end

return ai