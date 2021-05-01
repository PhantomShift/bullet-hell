local Vector2 = require "Vector2"

local cos = math.cos
local sin = math.sin
local ROOT_TWO = math.sqrt(2)

-- Module for creating paths that elements can follow
local path = {}

function path.Spiral(pos, rotSpeed, expansionSpeed, start)
    local start = start or 0
    return function(t)
        local t = ROOT_TWO * math.sqrt(t)
        local r = t * expansionSpeed
        local theta = start + rotSpeed * t
        return pos + Vector2.fromAngle(theta, r), r
    end
end
function path.Circle(center, rotSpeed, radius, start)
    local start = start or 0
    return function(t)
        return center + Vector2.fromAngle(start + rotSpeed * t, radius)
    end
end

return path