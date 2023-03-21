local combat = require "combat"
local gui = require "gui"

local component = {}

function component.targets(ecs_world)
    return ecs_world
        :get_component_table(nw.component.enemy_team)
        :keys()
        :filter(function(id) return combat.core.is_alive(ecs_world, id) end)
        :visit(print)
        :sort(function(a, b)
            local pa = math.abs(ecs_world:get(nw.component.board_index, a) or 0)
            local pb = math.abs(ecs_world:get(nw.component.board_index, b) or 0)
            return pa < pb
        end)
end

local function attack(ecs_world, data_id, user_id)
    local data = ecs_world:entity(data_id)
    
    local targets = data:ensure(component.targets, ecs_world)
    local menu = data
        :set(nw.component.drawable, nw.drawable.single_target_marker)
        :set(nw.component.color, 0.1, 0.2, 0.8)
        :set(nw.component.layer, 1)
        :set(nw.component.keybinding, {increase="right", decrease="left"})
        :ensure(nw.component.linear_menu_state, targets)
    --local bindings = data:ensure(nw.component.linear_menu_keys, "left", "right")
    if not menu.confirmed then return end
    local target = gui.menu.get_selected_item(data)

    if flag(data, "deal_damage") and target then
        local dmg = love.math.random(1, 3)
        combat.core.damage(ecs_world, target, dmg * 1000)
    end

    return true
end

return attack