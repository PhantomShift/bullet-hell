local Vector2 = require "Vector2"

local Max, Min = math.max, math.min
local function clamp(n, min, max)
    return Max(min, Min(n, max))
end
local function sign(n)
    if n > 0 then
        return 1
    elseif n < 0 then
        return -1
    end
    return n
end
local INF = 1/0

local ZERO_VECTOR = Vector2.new()

local geometry = {}
-- Checks for collision between a given circle and rectangle; returns offset needed to make circle no longer overlap with the rectangle. offset is Vector2 {0, 0} if not overlapping
function geometry.CircleVsRectangle(circle, rectangle)
    local NearestPoint = Vector2.new(
        clamp(circle.Position.X, rectangle.Position.X, rectangle.Position.X + rectangle.Width),
        clamp(circle.Position.Y, rectangle.Position.Y, rectangle.Position.Y + rectangle.Height)
    )
    local N = NearestPoint - circle.Position
    local overlap = circle.Radius - N.Magnitude
    if overlap == INF or overlap == - INF then overlap = 0 end
    if overlap > 0 then
        return - N.Unit * overlap
    end
    return ZERO_VECTOR
end
-- Chick if Vector2 point is in rectangle
function geometry.PointVsRectangle(rect, p)
    return (p.X >= rect.Position.X and p.y >= rect.Position.Y and p.X < rect.Position.X + rect.Width and p.Y < rect.Position.Y + rect.Height)
end
function geometry.RectVsRect(r1, r2)
    return (r1.Position.X < r2.Position.X + r2.Width and r1.Position.X + r1.Width > r2.Position.X and
            r1.Position.Y < r2.Position.Y + r2.Height and r1.Position.Y + r1.Height > r2.Position.Y)
end

function geometry.RayVsRect(ray_origin, ray_dir, target, ignore_negative)
    local t_near = (target.Position - ray_origin) / ray_dir
    local t_far = (target.Position + target:Size() - ray_origin) / ray_dir

    if (t_near.x > t_far.x) then t_near.x, t_far.x = t_far.x, t_near.x end
    if (t_near.y > t_far.y) then t_near.y, t_far.y = t_far.y, t_near.y end

    if not ignore_negative then
        if t_near.x > t_far.y or t_near.y > t_far.x then return false end
    end

    t_hit_near = Max(t_near.x, t_near.y)
    t_hit_far = Min(t_far.x, t_far.y)
    if ignore_negative then if t_hit_near < 0 then t_hit_near = t_hit_far end end
    print(t_hit_far)
    if t_hit_far < 0 and not ignore_negative then return false end

    local Point = ray_origin + t_hit_near * ray_dir
    local Normal
    if t_near.x > t_near.y then
        if ray_dir.x < 0 then
            Normal = Vector2.new(1, 0)
        else
            Normal = Vector2.new(-1, 0)
        end
    elseif t_near.x < t_near.y then
        if ray_dir.y < 0 then
            Normal = Vector2.new(0, 1)
        else
            Normal = Vector2.new(0, -1)
        end
    else
        Normal = Vector2.new(-sign(ray_dir.X), -sign(ray_dir.Y)).Unit
    end
    assert(Normal, tostring(Point))
    return {Point = Point, Normal = Normal, Time = t_hit_near}
end

function geometry.DynamicRectVsRect(rect, target, elapsedTime)
    if rect.Velocity.X == 0 and rect.Velocity.Y == 0 then
        return false
    end
    local expanded_target = geometry.Shapes.Rectangle.fromVectors(
        target.Position - rect:Size() / 2,
        target:Size() + rect:Size()
    )
    local result = geometry.RayVsRect(rect.Position + rect:Size() / 2, rect.Velocity * elapsedTime, expanded_target)
    if result then
        if result.Time <= 1 then
            return result
        end
    end
    return false
end
-- Naive check if ray intersects circle at all; only returns boolean
function geometry.CheckRayVsCircle(ray_start, ray_end, circle)
    -- check if starts or ends in circle; otherwise use projection
    if ray_start:distanceTo(circle.Position) < circle.Radius or ray_end:distanceTo(circle.Position) < circle.Radius then
        return true
    end
    local ray = ray_start - ray_end--ray_end - ray_start
    local to_circle = circle.Position - ray_start
    local projection = to_circle:Project(ray) --ray:Project(circle.Position)
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(0,0,0)
    love.graphics.circle("fill", ray_start.x + projection.x, ray_start.y + projection.y,50)
    --print("ray vs circle evaluated")
    love.graphics.setColor(r,g,b,a)
    return projection.Magnitude < ray.Magnitude and (ray_start + projection):distanceTo(circle.Position) < circle.Radius
end
-- Naive check if two circles are overlapping; only returns boolean
function geometry.CheckCircleVsCircle(circle1, circle2)
    return circle1.Position:distanceTo(circle2.Position) < circle1.Radius + circle2.Radius
end

local Circle = {
    __tostring = function(self)
        return "Shake: Circle, Position: "..tostring(self.Position)..", Radius: "..self.Radius
    end
}
Circle.__index = Circle
function Circle.new(posX, posY, radius)
    local circle = {
        Position = Vector2.new(posX, posY),
        Radius = radius
    }
    setmetatable(circle, Circle)
    return circle
end

local Rectangle = {
    Size = function(self) return Vector2.new(self.Width, self.Height) end,
    __tostring = function(self)
        return "Shape: Rectangle, Position: "..tostring(self.Position)..", Size: "..tostring(self:Size())
    end
}
Rectangle.__index = Rectangle
function Rectangle.new(posX, posY, width, height)
    local rectangle = {
        Position = Vector2.new(posX, posY),
        Width = width,
        Height = height,
        Velocity = Vector2.new()
    }
    setmetatable(rectangle, Rectangle)
    return rectangle
end
function Rectangle.fromVectors(position, size)
    return Rectangle.new(position.X, position.Y, size.X, size.Y)
end

geometry.Shapes = {
    Rectangle = Rectangle,
    Circle = Circle
}

return geometry
