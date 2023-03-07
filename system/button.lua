local button = {}

function button.spin(ecs_world)
    local element_clicked = ecs_world:get_component_table(nw.component.element_clicked)

    for _, id in pairs(element_clicked) do
        ecs_world:entity(id):set(nw.component.color, 1, 0, 0)
    end
end

return button