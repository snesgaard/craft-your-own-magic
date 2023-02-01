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

require "test.test_combat"
require "test.test_animation"
require "test.test_collision_helper"
require "test.test_trigger"
require "test.test_entity"
require "test.test_timer"
require "test.test_system"
require "test.test_fireball"
require "test.test_explosive_barrel"
require "test.test_jump"
require "test.test_coroutine_jump"
require "test.test_action_move"
require "test.test_decision"
