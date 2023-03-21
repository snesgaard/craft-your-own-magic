local combat = require "combat"
local gui = require "gui"

local component = {}

function component.targets(user_id) return user_id end

return function(ecs_world, data_id, user_id)
    local data = ecs_world:entity(data_id)

    local targets = list(user_id)
    local menu = data
        :set(nw.component.drawable, nw.drawable.single_target_marker)
        :set(nw.component.color, 0.1, 0.2, 0.8)
        :set(nw.component.layer, 1)
        :ensure(nw.component.linear_menu_state, targets)
    
    if not menu.confirmed then return end

    if flag(data, "heal") and user_id then
        combat.core.heal(ecs_world, user_id, 10)
    end
    
    return true
end