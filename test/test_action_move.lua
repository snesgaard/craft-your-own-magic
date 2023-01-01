local action = require("ai").action

T("test_action_move", function(T)
    local ecs_world = nw.ecs.entity.create()
    local entity = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity, 100, 100,
            spatial(1, 1, 1, 1)
        )

    local world = nw.ecs.world()

    local speed = 10
    local ctx = world:push(action.move, entity, vec2(200, 100), speed)

    T("multi_steps", function(T)
        for i = 1, 10 do
            T:assert(ctx:is_alive())
            world:emit("update", 1):spin()
            T:assert(entity:get(nw.component.position).x == 100 + i * 10)
            T:assert(entity:get(nw.component.position).y == 100)
        end
        T:assert(not ctx:is_alive())
    end)
end)

T("test_action_wait", function(T)
    local world = nw.ecs.world()
    local duration = 10
    local ctx = world:push(action.wait, duration)

    local dt = 0.016
    local steps = math.ceil(duration / dt)
    for i = 1, steps do
        T:assert(ctx:is_alive())
        world:emit("update", dt):spin()
    end
    T:assert(not ctx:is_alive())
end)

T("test_patrol", function(T)
    local patrol = list(
        vec2(0, 0),
        vec2(0, 100),
        vec2(100, 100)
    )

    local ecs_world = nw.ecs.entity.create()
    local entity = ecs_world:entity()
        :assemble(
            nw.system.collision().assemble.init_entity,
            0, 0, spatial(1, 1, 1, 1)
        )

    local world = nw.ecs.world()
    local ctx = world:push(action.patrol, entity, patrol, 10, 0.5)
    while ctx:is_alive() do
        world:emit("update", 0.16):spin()
    end
    T:assert(entity:get(nw.component.position).x == 100)
    T:assert(entity:get(nw.component.position).y == 100)
end)
