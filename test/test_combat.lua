local combat = require "system.combat"

T("combat", function(T)
    local ecs_world = nw.ecs.entity.create()

    local target = ecs_world:entity()
        :set(nw.component.health, 5, 10)

    T("damage", function(T)
        local info = combat():damage(target, 3)
        T:assert(info.target == target)
        T:assert(info.damage == 3)
        T:assert(target:get(nw.component.health).value == 2)
        T:assert(target:get(nw.component.health).max == 10)
        T:assert(not info.death)
    end)

    T("heal", function(T)
        local info = combat():heal(target, 2)
        T:assert(info.target == target)
        T:assert(info.heal == 2)
        T:assert(target:get(nw.component.health).value == 7)
        T:assert(target:get(nw.component.health).max == 10)
    end)

    T("die", function(T)
        local info = combat():damage(target, 100)
        T:assert(info.death)

        local brittle = ecs_world:entity()
            :set(nw.component.brittle)

        local info = combat():damage(brittle, 1)

        T:assert(not info.damage)
        T:assert(info.death)
    end)
end)
