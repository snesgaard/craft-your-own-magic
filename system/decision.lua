local Base = require "system.base"

local Decision = Base()

local function sort_by_score(task1, task2)
    return task1.score < task2.score
end

local function pick_best_task(tasks_and_scores)
    table.sort(tasks_and_scores, sort_by_score)
    local best_task = tasks_and_scores:head()
    if not best_task then return end
    return best_task
end

local function evaluate_decision(ctx, entity, decision)
    local tasks_and_scores = list()

    for _, func in pairs(decision) do
        local action_score = func(entity)
        if action_score and action_score.score > 0 then
            table.insert(tasks_and_scores, action_score)
        end
    end

    local next_task = pick_best_task(tasks_and_scores)

    if not next_task then return end

    entity:map(nw.component.task, function(current_task)
        return current_task:set(next_task.func, ctx, unpack(next_task.args or {}))
    end)
end

local function should_evaluate_decision() return true end

function Decision.run_decisions(ctx, ecs_world)
    local decision_table = ecs_world:get_component_table(nw.component.decision)
    for id, decision in pairs(decision_table) do
        local entity = ecs_world:entity(id)
        if should_evaluate_decision(entity, decision) then
            evaluate_decision(ctx, entity, decision)
        end
    end
end

function Decision.run_tasks(ctx, ecs_world)
    local task_table = ecs_world:get_component_table(nw.component.task)
    for id, task in pairs(task_table) do
        local res = task:resume()
        if res:has_error() then
            print("Task failed => ", res:message())
        end
    end
end

function Decision.handle_observables(ctx, obs, ecs_world)
    Decision.run_decisions(ctx, ecs_world)
    Decision.run_tasks(ctx, ecs_world)
end

return Decision.from_ctx
