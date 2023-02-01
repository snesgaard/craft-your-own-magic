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

require "test.test_collision_helper"
require "test.test_entity"
require "test.test_timer"
require "test.test_jump"
