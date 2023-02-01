local decision = require "system.decision"

local comp = {}

function comp.A() return true end

function comp.B() return true end

local task = {}

function task.A(ctx, entity)
    entity:set(comp.A)
end

function task.B(ctx, entity)
    entity:set(comp.B)
end

local task_decisions = {}

function task_decisions.A(entity)
    return {
        score = entity:has(comp.A) and 0 or 1,
        func = task.A,
        args = {entity}
    }
end

function task_decisions.B(entity)
    return {
        score = entity:has(comp.A) and 1 or 0,
        func = task.B,
        args = {entity}
    }
end

T("test_decision", function(T)
    local world = nw.ecs.world()
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity("item")
        :set(nw.component.decision, task_decisions)

    local ctx = world:push(function(ctx)
        ctx:spin()
    end)

    decision().run_decision_and_task(ctx, {}, ecs_world)

    local item_task = item:get(nw.component.task)
    T:assert(item_task)
    T:assert(item_task:func() == task.A)
    T:assert(item:get(comp.A))

    decision().run_decision_and_task(ctx, {}, ecs_world)

    local item_task = item:get(nw.component.task)
    T:assert(item_task)
    T:assert(item_task:func() == task.B)
    T:assert(item:get(comp.B))
end)
