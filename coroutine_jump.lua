coroutine.jump_table = setmetatable({}, {__mode = "vk"})

local function should_change_jump_table(jt, args)
    if not jt then return true end
    -- Maybe handle death here
    return jt.args ~= args
end

local function handle_jump_return(status, msg, ...)
    if not status then errorf("error in jump %s", msg) end
    return msg, ...
end

function coroutine.jump(func, ...)
    local co = coroutine.running() or "__main__"
    local args = list(func, ...)
    local jt = coroutine.jump_table[co]

    if should_change_jump_table(jt, args) then
        jt = {
            co = coroutine.create(func),
            args = args,
            co_args = {...}
        }
        coroutine.jump_table[co] = jt
    end

    if coroutine.status(jt.co) == "dead" then return end

    return handle_jump_return(coroutine.resume(jt.co, unpack(jt.co_args)))
end
