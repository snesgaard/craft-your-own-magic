local Timeline = class()

function Timeline.create(nodes, ease)
    return setmetatable({nodes=nodes, ease=ease}, Timeline)
end

local function eval_nodes(ease, time, prev_node, next_node)
    if not prev_node then return next_node.value end
    if not next_node then return prev_node.value end

    if not ease then return prev_node.value end

    prev_node[next_node] = prev_node[next_node] or (next_node.value - prev_node.value)
    local duration = next_node.time - prev_node.time

    if duration == math.huge then
        return prev_node.value
    end

    return ease(
        time - prev_node.time,
        prev_node.value,
        prev_node[next_node],
        duration
    )
end

function Timeline:value(time, ease)
    local ease = ease or self.ease
    for i = 1, #self.nodes + 1 do
        local prev_node = self.nodes[i - 1]
        local next_node = self.nodes[i]

        local prev_time = prev_node and prev_node.time or -math.huge
        local next_time = next_node and next_node.time or math.huge
        if prev_time <= time and time < next_time then
            return eval_nodes(ease, time, prev_node, next_node)
        end
    end
end

function Timeline:duration()
    local duration = 0
    for _, node in ipairs(self.nodes) do
        if node.time ~= math.huge and node.time ~= -math.huge then
            duration = node.time
        end
    end
    return duration
end

function Timeline:__tostring()
    return string.format("Timeline: %s: %s", self.name, tostring(self.nodes))
end

local Animation = class()

function Animation.create()
    return setmetatable({timelines=list()}, Animation)
end

function Animation:tween(args)
    args.delay = args.delay or 0
    local nodes = list(
        {value=args.from, time=args.delay},
        {value=args.to, time=args.delay + args.duration}
    )
    return self:timeline(args.name, nodes, args.ease or ease.linear)
end

function Animation:timeline(name, nodes, ease)
    local t = Timeline.create(nodes, ease)
    t.name = name
    table.insert(self.timelines, t)
    return self
end

function Animation:value(time)
    local values = dict()

    for _, timeline in ipairs(self.timelines) do
        values[timeline.name] = timeline:value(time)
    end

    return values
end

function Animation:duration()
    local duration = 0
    for _, timeline in ipairs(self.timelines) do
        duration = math.max(timeline:duration(), duration)
    end
    return duration
end

local AnimationPlayer = class()

function AnimationPlayer.create(animation)
    return setmetatable(
        {
            time = 0,
            once = false,
            speed = 1,
            animation = animation or Animation.create()
        },
        AnimationPlayer
    )
end

function AnimationPlayer:__eq(other)
    return other.animation == self.animation
end

function AnimationPlayer:done()
    return self:duration() <= self.time
end

local function update_time(self, dt)
    self.time = self.time + dt
    if self.time < self:duration() or self.once then return end
    if self:duration() <= 0 then return end

    while self:duration() <= self.time do
        self.time = self.time - self:duration()
    end
end

function AnimationPlayer:update(dt)
    local prev_values = self:value()

    if self._on_update and self._on_update_next then
        self._on_update_next = false
        self._on_update(self:value(), {})
    end

    update_time(self, dt * self.speed)

    if self._on_update then
        local values = self:value()
        self._on_update(values, prev_values)
    end

    return self:done()
end

function AnimationPlayer:set_speed(speed)
    self.speed = speed or 1
    return self
end

function AnimationPlayer:spin(ctx)
    local update = ctx:listen("update"):collect()

    while ctx:is_alive() and not self:done() do
        for _, dt in ipairs(update:pop()) do
            self:update(dt)
        end
        ctx:yield()
    end
end

function AnimationPlayer:spin_once(ctx)
    self.update_obs = self.update_obs or ctx:listen("update"):collect()

    for _, dt in ipairs(self.update_obs:pop()) do self:update(dt) end

    return self:done()
end

function AnimationPlayer:on_update(func)
    self._on_update = func
    self._on_update_next = true
    return self
end

function AnimationPlayer:value()
    return self.animation:value(self.time)
end

function AnimationPlayer:play_once()
    self.once = true
    return self
end

function AnimationPlayer:set_duration(duration)
    self._duration = duration
    return self
end

function AnimationPlayer:duration()
    self._duration = self._duration or self.animation:duration()
    return self._duration
end

function AnimationPlayer:play_in_seconds(seconds)
    if not seconds then return self end
    local speed = self:duration() / seconds
    return self:set_speed(speed)
end

local function step(args)
    return list(
        {value=args.min, time=-math.huge},
        {value=args.max, time=args.start},
        {value=args.min, time=args.stop}
    )
end

local function lerp(args)
    local delay = args.delay or 0
    return list(
        {value=args.from, time=delay},
        {value=args.to, time=delay + args.duration}
    )
end

local function sequence(seq)
    local nodes = list()

    if #seq == 0 then return nodes end

    local time = 0

    for _, s in ipairs(seq) do
        local n = {value=s.value, time=time}
        table.insert(nodes, n)
        time = time + s.dt
    end

    local last_value = List.tail(seq).value
    table.insert(nodes, dict{value=last_value, time=time})

    return nodes
end

local function lift_to_node(frame)
    return dict{value=frame, dt=frame.dt}
end

local function from_aseprite(atlas, key)
    local frames = get_atlas(atlas):get_animation(key):map(lift_to_node)

    return Animation.create()
        :timeline("frame", sequence(frames))
end

return {
    player = AnimationPlayer.create,
    animation = Animation.create,
    step = step,
    lerp = lerp,
    sequence = sequence,
    from_aseprite = from_aseprite
}
