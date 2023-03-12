local input = require "system.input"

local menu = {}

function menu.update_state(ecs_world, id, menu_state)
    if menu_state.confirmed then return end

    if input.is_pressed(ecs_world, "down") then
        if #menu_state.items <= menu_state.index then
            menu_state.index = 1
        else
            menu_state.index = menu_state.index + 1
        end 
    end

    if input.is_pressed(ecs_world, "up") then
        if menu_state.index <= 1 then
            menu_state.index = #menu_state.items
        else
            menu_state.index = menu_state.index - 1
        end
    end

    if input.is_pressed(ecs_world, "space") then
        menu_state.confirmed = true
    end
end

function menu.spin(ecs_world)
    local t = ecs_world:get_component_table(nw.component.linear_menu_state)
    for id, state in pairs(t) do
        menu.update_state(ecs_world, id, state)
    end
end

function menu.get_selected_item(entity)
    local menu_state = entity:get(nw.component.linear_menu_state)
    if not menu_state or not menu_state.confirmed then return end
    return  menu_state.items[menu_state.index]
end

return menu