T("test_coroutine_jump", function(T)
    local dst = {}

    local function A()
        dst.A = true
    end
    local function B()
        dst.B = true
        coroutine.jump(A)
    end

    T("jump_from_main", function(T)
        coroutine.jump(B)

        T:assert(dst.A)
        T:assert(dst.B)

        coroutine.jump(B)
    end)

    T("jump_from_B", function(T)
        local co = coroutine.create(B)
        local status = coroutine.resume(co)
        T:assert(status)
        T:assert(dst.A)
        T:assert(dst.B)
        T:assert(coroutine.jump_table[co])
        co = nil
        collectgarbage()
        T:assert(not coroutine.jump_table[co])
    end)
end)
