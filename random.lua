local random = {}

function random.uniform(min, max)
    return {
        type = "uniform",
        min = min,
        max = max
    }
end

function random.normal(std, mean)
    return {
        type = "normal",
        std = std,
        mean = mean
    }
end

function random.get(distribution)
    if type(distribution) ~= "table" then return distribution end

    if distribution.type == "uniform" then
        return love.math.random(distribution.min, distribution.max)
    elseif distribution.type == "normal" then
        return love.math.randomNormal(distribution.std, distribution.mean)
    else
        errorf("Unknown distribution type: %s", distribution.type)
    end
end

return random