T = nw.third.knife.test

TestContext = class()

function TestContext.create()
    return setmetatable(
        {
            events = list()
        },
        TestContext
    )
end

function TestContext:emit(key, ...)
    table.insert(self.events, {key = key, ...})
end

require "test.combat"
require "test.animation"
require "test.test_collision_and_effect"
