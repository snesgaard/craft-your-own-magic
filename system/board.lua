local painter = require "painter"

local board = {}

function board.sign(x)
    if x < 0 then
        return -1
    elseif 0 < x then
        return 1
    else
        return 0
    end
end

function board.position_from_index(index, w)
    local o = 0.0
    local x = 0.5 + o * board.sign(index) + 0.1 * index
    local y = 0.75
    return painter.norm_to_real(x, y)
end

function board.world_position(ecs_world, id)
    return ecs_world:entity(id)
        :maybe_get(nw.component.board_index)
        :map(board.position_from_index)
end

function board.query_index(ecs_world, dst)
    return ecs_world
        :get_component_table(nw.component.board_index)
        :filter(function(id, index) return index == dst end)
        :keys()
        :unpack()
end

function board.move_to_index(entity, dst)
    local is_occupied = board.query_index(entity:world(), dst)
    
    if is_occupied then return false end

    entity:set(nw.component.board_index, dst)

    return true
end

function board.spin(ecs_world)
    for id, index in pairs(ecs_world:get_component_table(nw.component.board_index)) do
        local x, y = board.position_from_index(index)
        ecs_world:ensure(nw.component.position, id, x, y)
    end
end

return board