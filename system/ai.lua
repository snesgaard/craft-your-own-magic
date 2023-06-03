local ai = {}

local function run_task(data, task_func, ...)
    return task_func(data, ...)
end

local function task_status() return {} end

local function task_data() return {} end

function ai.sequence(data, ...)
    local tasks = {...}
    local task_status = stack.ensure(task_status, data)
    local task_data = stack.ensure(task_data, data)

    for i, task in ipairs(tasks) do
        task_data[i] = task_data[i] or nw.ecs.id.weak("task")
        if not task_status[i] or task_status[i] == "pending" then
            task_status[i] = run_task(task_data[i], unpack(task))
        end
        if task_status[i] ~= "success" then return task_status[i] end
    end

    return "success"
end

function ai.sequence_forget_failure(data, ...)
    local status = ai.sequence(data, ...)
    if status == "failure" then stack.remove(task_status, data) end
    return status
end

function ai.sequence_forget(data, ...)
    local status = ai.sequence(data, ...)
    if status ~= "pending" then
        stack.remove(task_status, data)
        stack.remove(task_data, data)
    end
    return status
end

function ai.select(data, ...)
    local tasks = {...}
    local task_status = stack.ensure(task_status, data)
    local task_data = stack.ensure(task_data, data)

    for i, task in ipairs(tasks) do
        task_data[i] = task_data[i] or nw.ecs.id.weak("task")
        if not task_status[i] or task_status[i] == "pending" then
            task_status[i] = run_task(task_data[i], unpack(task))
        end
        if task_status[i] ~= "failure" then return task_status[i] end
    end

    return "failure"
end

function ai.stateless_select(data, ...)
    local status = ai.select(data, ...)
    stack.remove(task_status, data)
    return status
end

function ai.select_forget(data, ...)
    local status = ai.select(data, ...)
    if status ~= "pending" then
        stack.remove(task_status, data)
        stack.remove(task_data, data)
    end
    return status
end

function ai.run(data, task)
    return run_task(data, unpack(task))
end

function ai.action(data, func, ...)
    func(...)
    return "success"
end

function ai.condition(data, func, ...)
    return func(...) and "success" or "failure"
end

return ai