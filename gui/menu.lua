local input = require "system.input"

local menu = {}

local default_key_binding = {increase="down", decrease="up", confirm="space"}

function menu.update_state(ecs_world, id, menu_state)
    if menu_state.confirmed then return end

    local keybinding = ecs_world:get(nw.component.keybinding, id) or default_key_binding
    keybinding.increase = keybinding.increase or default_key_binding.increase
    keybinding.decrease = keybinding.decrease or default_key_binding.decrease
    keybinding.confirm = keybinding.confirm or default_key_binding.confirm

    if input.is_pressed(ecs_world, keybinding.increase) then
        if #menu_state.items <= menu_state.index then
            menu_state.index = 1
        else
            menu_state.index = menu_state.index + 1
        end 
    end

    if input.is_pressed(ecs_world, keybinding.decrease) then
        if menu_state.index <= 1 then
            menu_state.index = #menu_state.items
        else
            menu_state.index = menu_state.index - 1
        end
    end

    if input.is_pressed(ecs_world, keybinding.confirm) then
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
    return menu_state.items[menu_state.index]
end

return menu