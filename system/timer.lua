local timer = {}

function timer.is_done(id)
    local time, duration = timer.get(id)
    if not time then return end
    return duration <= time
end

function timer.get(id)
    local t = stack.get(nw.component.timer, id)
    if not t then return end
    return clock.get() - t.time, t.duration
end

function timer.spin()
    local kill_these = list()

    for id, _ in stack.view_table(nw.component.die_on_timer_done) do
        if timer.is_done(id) == true then table.insert(kill_these, id) end
    end

    for _, id in ipairs(kill_these) do
        stack.destroy(id)
    end
end

return timer