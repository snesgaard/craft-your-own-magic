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
require "test.timer"
require "test.effect_resolution"
require "test.collision"
require "test.animation"
