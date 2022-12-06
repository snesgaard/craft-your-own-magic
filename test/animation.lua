local animation = require "system.animation"

T("animation", function(T)
    T("data", function(T)
        local animation = animation.animation()
            :timeline(
                "test",
                list(
                    {value=0, time=-math.huge},
                    {value=1, time=0},
                    {value=2, time=2},
                    {value=3, time=math.huge}
                ),
                ease.linear
            )
            :timeline(
                "test2",
                animation.step{min=0, max=2, start=0, stop=10}
            )
            :timeline(
                "test3",
                animation.step{min=false, max=true, start=1, stop=3}
            )
            :timeline(
                "lerp",
                animation.lerp{from=0, to=10, delay=1, duration=1},
                ease.linear
            )

        T:assert(animation:duration() == 10)
        T:assert(animation:value(0).test == 1)
        T:assert(animation:value(5).test == 2)
        T:assert(animation:value(1).test == 1.5)

        T:assert(animation:value(-1).test2 == 0)
        T:assert(animation:value(1).test2 == 2)
        T:assert(animation:value(2).test2 == 2)
        T:assert(animation:value(12).test2 == 0)

        T:assert(not animation:value(0).test3)
        T:assert(animation:value(2).test3)
        T:assert(not animation:value(4).test3)

        T:assert(animation:value(0).lerp == 0)
        T:assert(animation:value(1.5).lerp == 5)
        T:assert(animation:value(2).lerp == 10)
    end)

    T("player", function(T)
        local data = animation.animation()
            :timeline(
                "value",
                animation.lerp{from=0, to=1, duration=10},
                ease.linear
            )

        local update_called = {count=-1}

        local player = animation.player(data)
            :on_update(function() update_called.count = update_called.count + 1 end)

        T:assert(player:duration() == 10)

        player:update(1)
        T:assert(update_called.count == 1)
        T:assert(player:value().value == 0.1)

        player:update(1)
        T:assert(update_called.count == 2)
        T:assert(player:value().value == 0.2)

        T("once", function(T)
            player:play_once():update(10)
            T:assert(update_called.count == 3)
            T:assert(player:value().value == 1)
        end)
        T("repeat", function(T)
            player:update(10)
            T:assert(update_called.count == 3)
            T:assert(player:value().value == 0.2)
        end)
    end)

    T("sequence", function(T)
        local seq = {
            {value=1, dt=1},
            {value=2, dt=1},
            {value=3, dt=1},
        }

        local data = animation.animation()
            :timeline(
                "sequence",
                animation.sequence(seq)
            )

        T:assert(data:value(0.5).sequence == 1)
        T:assert(data:value(1.5).sequence == 2)
        T:assert(data:value(2.5).sequence == 3)
        T:assert(data:value(3.5).sequence == 3)
        T:assert(data:duration() == 3)
    end)
end)
