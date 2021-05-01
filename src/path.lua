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
function path.Linear(speed, ...)
    local positions = {...}
    assert(#positions > 1, "Must provide at least two positions")
    local track = 1
    local current, goal = positions[1], positions[2]
    local timeToComplete= current:distanceTo(goal) / speed
    local lifetime = 0
    return function(t)
        local c, g = current, goal
        lifetime = lifetime + t
        t = lifetime / timeToComplete
        if t > 1 and track < #positions then
            track = track + 1
            current, goal = positions[track], positions[track+1]
            timeToComplete = goal and current:distanceTo(goal) or nil
        end
        return c:Lerp(g, t), timeToComplete
    end
end

return path