local jump = require "system.jump"

T("test_jump", function(T)
    local ecs_world = nw.ecs.entity.create()
    local item = ecs_world:entity("item")
        :set(nw.component.jump, 100)
        :set(nw.component.velocity, 0, 100)
        :set(nw.component.gravity)

    local other = ecs_world:entity("other")

    T("forced_jump", function(T)
        jump().execute_jump(item)
        T:assert(item:get(nw.component.velocity).y < 0)
    end)

    T("jump_from_events", function(T)
        jump():request(item)
        T:assert(item:get(nw.component.velocity).y >= 0)
        jump():update(0, ecs_world)
        T:assert(item:get(nw.component.velocity).y >= 0)
        local fake_col_info = {
            ecs_world = ecs_world,
            type = "slide",
            normal = vec2(0, -1),
            item = item.id,
            other = other.id
        }
        jump():on_collision(fake_col_info)
        T:assert(jump():jump_if_can(item))
        T:assert(item:get(nw.component.velocity).y < 0)

        jump():on_collision(fake_col_info)
        jump():request(item)
        T:assert(not jump():jump_if_can(item))
    end)
end)
