local combat = require "combat"
local action = require "system.action_animation"

local targeting = {}

targeting["all/enemy"] = function(ecs_world, user)
    return combat.target.get_targets(ecs_world, user)
end

targeting["single/enemy"] = function(ecs_world, user)
    return list(combat.target.get_targets(ecs_world, user):head())
end

targeting["single/enemy/random"] = function(ecs_world, user)
    return list(combat.target.get_targets(ecs_world, user):shuffle():head())
end

targeting["self"] = function(ecs_world, user)
    return list(user)
end

function targeting.eval_target(ecs_world, user, target_type)
    local func = targeting[target_type]
    if not func then return end
    return func(ecs_world, user)
end

function targeting.visit_node(ecs_world, user, node, dst)
    local dst = dst or dict()
    if node.target then
        print("evaluating target", node.target)
        dst[node.target] = dst[node.target] or targeting.eval_target(ecs_world, user, node.target)
    end

    for _, child in ipairs(node) do
        targeting.visit_node(ecs_world, user, child, dst)
    end

    return dst
end

function targeting.select(ecs_world, user, ability)
    local targets = targeting.visit_node(ecs_world, user, ability)
    return targets
end

function targeting.read_target_from_table(target_table, target_type)
    if not target_type then return end
    return target_table[target_type]
end

local executor = {}

function executor.attack(ecs_world, node, user, targets)
    print("attacking:", user, targets, node.power)
    for _, target in ipairs(targets) do
        combat.core.attack(ecs_world, user, target, node.power)
    end
end

function executor.status(ecs_world, node, user, targets)
    print("applying status:", node.status, targets)
    for _, id in ipairs(targets) do
        combat.core.apply_status(ecs_world, user, id, node.status, node.power)
    end
end

function executor.node_func_from_type(call_type)
    print("finding node type", call_type)
    if not call_type then return end
    return executor[call_type]
end

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

local function should_exhaust(card)
    return card and card.exhaust
end

function ai.card_state_from_deck(ecs_world, id, deck)   
    local deck = deck or ecs_world:get(nw.component.ai_deck, id)
    if not deck then return end
    if ecs_world:has(nw.component.ai_state, id) then return end
    local innate = deck:filter(function(a) return a.innate end)
    local not_innate = deck:filter(function(a) return not a.innate end)
    local draw = innate:shuffle() + not_innate:shuffle()
    ecs_world:set(nw.component.ai_state, id, draw)
end

function ai.advance_action_deck(ecs_world, id)
    local user = ecs_world:entity(id)
    local ai = user:ensure(nw.component.ai_state)

    if should_exhaust(ai.intent) then
        ai.exhaust = ai.exhaust:insert(ai.intent)
    else
        ai.discard = ai.discard:insert(ai.intent)
    end

    if ai.draw:empty() then
        ai.draw = ai.discard:shuffle()
        ai.discard = list()
    end

    ai.intent = ai.draw:head()
    ai.draw = ai.draw:body()

    return ai.discard
end

function ai.get_next_action(ecs_world, id)
    local user = ecs_world:entity(id)
    local ai = user:ensure(nw.component.ai_state)
    return ai.intent
end

function ai.prepare_next_action(ecs_world, id)
    ai.advance_action_deck(ecs_world, id)
    return ai.get_next_action(ecs_world, id)
end

function ai.execute_node(ecs_world, user, node, target_table)
    local target = targeting.read_target_from_table(target_table, node.target)
    local func = executor.node_func_from_type(node.type)
    if not target or not func then return end
    return func(ecs_world, node, user, target)
end

function ai.evaluate_node(ecs_world, user, node, target_table, dst)
    dst[node] = ai.execute_node(ecs_world, user, node, target_table)

    for _, child in ipairs(node) do
        ai.evaluate_node(ecs_world, user, child, target_table, dst)
    end

    return dst
end

function ai.flatten_ability(node, dst)
    local dst = dst or {}
    table.insert(dst, node)
    for _, c in ipairs(node) do ai.flatten_ability(c, dst) end
    return dst
end

function ai.play_ability(ecs_world, user, ability)
    if not user then error("User was nil") end
    local dst = dict()
    if not ability then return dst end
    local target_table = targeting.select(ecs_world, user, ability)
    return ai.evaluate_node(ecs_world, user, ability, target_table, dst)
end

ai.execute_node_store = nw.component.relation(ai.execute_node)

function ai.run_next(ecs_world, user, ability, id)
    local data = ecs_world:entity(id)
    if not user or not ability then error("User was nil") end
    local target_table = data:ensure(targeting.select, ecs_world, user, ability)
    local flatten = data:ensure(ai.flatten_ability, ability)

    for _, node in ipairs(flatten) do
        local comp = ai.execute_node_store:ensure(node)
        if not data:has(comp) then
            local result = data:ensure(comp, ecs_world, user, node, target_table)
            if result then return result end
        end
    end
end

function ai.ability_execution(ecs_world, user, ability)
    return ecs_world:entity():set(nw.component.ability_execution, user, ability)
end

function ai.run_next_ability(data)
    local exec = data:get(nw.component.ability_execution)
    if not exec then return end
    local user, ability = exec.user, exec.ability
    if not user or not ability then return end
    print("running next for ability:", user, ability)
    local target_table = data:ensure(targeting.select, ecs_world, user, ability)
    local flatten = data:ensure(ai.flatten_ability, ability)

    for _, node in ipairs(flatten) do
        local comp = ai.execute_node_store:ensure(node)
        if not data:has(comp) then
            local result = data:ensure(comp, ecs_world, user, node, target_table)
            if result then return result end
        end
    end
end

function ai.run_all_ability(data)
    while ai.run_next_ability(data) do end
    return data
end

function ai.run_action(ecs_world, data_id, user, ability, target)

    return true
end

function ai.execute_turn(ecs_world, user)
    -- Setup entity
    local id = string.format("turn:%s", tostring(user))
    local data = ecs_world:entity(id)

    -- Select ability
    local ability_data = data:ensure(combat.ability_select.component, ecs_world, user)
    if not combat.ability_select.is_done(ability_data) then return end
    local ability = combat.ability_select.get(ability_data)

    -- Select target
    local target_data = data:ensure(combat.target.component, ecs_world, user, ability)
    if combat.target.is_cancel(target_data) then
        data:remove(combat.target.component)
        combat.ability_select.reset(ability_data)
        return
    end
    if not combat.target.is_done(target_data) then return end
    local target = combat.target.get(target_data)

    -- Execute ability
    local action_data = data:ensure(action.submit, ecs_world, combat.ability_execution, user, ability, target)
    if not action.empty(ecs_world) then return end

    return data
end

return ai