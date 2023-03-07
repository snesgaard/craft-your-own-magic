local function is_clicked(entity, click)
    local pos = entity:ensure(nw.component.position)
    local rect = entity:get(nw.component.mouse_rect)

    return rect:point_inside(click.x - pos.x, click.y - pos.y)
end

local function handle_click(ecs_world, click)
    local rects = ecs_world:get_component_table(nw.component.mouse_rect)
    
    for id, _ in pairs(rects) do
        if is_clicked(ecs_world:entity(id), click) then
            ecs_world:entity(id)
                :set(nw.component.is_down)
                :set(nw.component.pressed)
        end
    end
end

local function handle_release(ecs_world, click)
    local rects = ecs_world:get_component_table(nw.component.mouse_rect)
    
    for id, _ in pairs(rects) do
        
    end

    for _, id in ipairs(ecs_world:get_component_table(nw.component.is_down):keys()) do
        ecs_world:remove(nw.component.is_down, id)
    end
end

local function handle_update(ecs_world, dt)
    -- Undo temporary components 
    local pressed = ecs_world:get_component_table(nw.component.pressed):keys()
    for _, id in pairs(pressed) do
        ecs_world:remove(nw.component.pressed, id)
    end
end

local mouse = {}

-- Create generic mouse events
function mouse.spin(ecs_world)
    local clicks = ecs_world:get_component_table(nw.component.mousepressed)
    local release = ecs_world:get_component_table(nw.component.mousereleased)
    local update = ecs_world:get_component_table(nw.component.update)

    for _, dt in pairs(update) do
        handle_update(ecs_world, dt)
    end

    for _, click in pairs(clicks) do
        handle_click(ecs_world, click)
    end

    for _, release in pairs(release) do
        handle_release(ecs_world, release)
    end
end

function mouse.draw()

end

return mouse