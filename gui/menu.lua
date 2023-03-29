local input = require "system.input"

local menu = {}

local default_key_binding = {
    increase="down", decrease="up", confirm="space", cancel="b"
}

function menu.update_state(ecs_world, id, menu_state)
    if menu_state.confirmed or menu_state.cancel then return end

    local keybinding = ecs_world:get(nw.component.keybinding, id) or default_key_binding
    keybinding.increase = keybinding.increase or default_key_binding.increase
    keybinding.decrease = keybinding.decrease or default_key_binding.decrease
    keybinding.confirm = keybinding.confirm or default_key_binding.confirm
    keybinding.cancel = keybinding.cancel or default_key_binding.cancel

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
        local f = ecs_world:get(nw.component.linear_menu_filter, id)
        if not f or f(menu_state.items[menu_state.index]) then
            menu_state.confirmed = true
        end
    end

    if input.is_pressed(ecs_world, keybinding.cancel) then
        menu_state.cancel = true
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
    return menu_state.items[menu_state.index], menu_state.index
end

function menu.is_done(entity) return menu.is_confirmed(entity) or menu.is_cancel(entity) end

function menu.is_confirmed(entity)
    local menu_state = entity:get(nw.component.linear_menu_state)
    if not menu_state then return end
    return menu_state.confirmed
end

function menu.reset(entity)
    local menu_state = entity:get(nw.component.linear_menu_state)
    if not menu_state then return end
    menu_state.confirmed = nil
    menu_state.cancel = nil
end

function menu.is_cancel(entity)
    local menu_state = entity:get(nw.component.linear_menu_state)
    if not menu_state then return end
    return menu_state.cancel
end

return menu