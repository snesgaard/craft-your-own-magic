local clock = {id = "__clock__"}

function clock.spin()
    for _, dt in event.view("update") do clock.update(dt) end
end

function clock.update(dt)
    stack.set(nw.component.time, clock.id, clock.get() + dt)
end

function clock.get()
    return stack.ensure(nw.component.time, clock.id)
end

return clock