local function custom_type(obj)
    local t = type(obj)
    if t ~= "table" then
        return t
    end
    if getmetatable(obj) and getmetatable(obj).__type then
        return getmetatable(obj).__type
    end
    return ""
end

-- Class that handles vectors in 2D space. | Constructors: new(x, y), fromAngle(angle, magnitude, Degrees) | Properties: number x, number y, number Magnitude, Vector2 Unit | Methods: Vector2 Rotate(angle, Degrees), number distanceTo(Vector2), number Dot(Vector2)
local Vector2 = {}
-- metamethods

function Vector2:__index(key)
    if string.lower(key) == "magnitude" then
        local x, y = self.__true.X, self.__true.Y
        return math.sqrt(x * x + y * y)
    elseif string.lower(key) == "unit" then
        local m = self.Magnitude
        if m > 0 then
            return Vector2.new(self.__true.x / m, self.__true.y / m)
        end
        return self
    end
    if Vector2[key] then
        return Vector2[key]
    end
    return self.__true[key]
end
-- returned by custom_type(v)
Vector2.__type = "Vector2"
function Vector2:__newindex(key, value)
    error "Properties of Vector2s cannot be changed directly"
    -- local self = self.__true
    -- if type(key) == "string" and (string.lower(key) == "x" or string.lower(key) == "y") then
    --     rawset(self, string.upper(key), value)
    -- else
    --     error "Properties other than X or Y of Vector2s cannot be changed directly"
    -- end
    -- local x, y = (self.X), self.Y
    -- rawset(self, "x", x)
    -- rawset(self, "y", y)
    --rawset(self, "Magnitude", math.sqrt(x * x + y * y))
    --rawset(self, "magnitude", self.Magnitude)
    -- if self.Magnitude > 0 then
    --     rawset(self, "Unit", Vector2.new(x, y) / self.Magnitude)
    -- else
    --     rawset(self, "Unit", self)
    -- end
    -- rawset(self, "unit", self.Unit)
end
function Vector2:__eq(t)
    return custom_type(t) == "Vector2" and self.x == t.x and self.y == t.y
end
function Vector2:__add(t)
    assert(custom_type(t) == "Vector2", "Vector2 can only be added with other Vector2s")
    return Vector2.new(self.x + t.x, self.y + t.y)
end
function Vector2:__sub(t)
    assert(custom_type(t) == "Vector2", "Vector2 can only be subtracted by other Vector2s")
    return Vector2.new(self.x - t.x, self.y - t.y)
end
function Vector2:__unm()
    return Vector2.new(-self.x, -self.y)
end
function Vector2.__mul(o1, o2)
    if type(o1) == "number" then
        return Vector2.new(o1 * o2.x, o1 * o2.y)
    elseif type(o2) == "number" then
        return Vector2.new(o1.x * o2, o1.y * o2)
    elseif custom_type(o1) == "Vector2" and custom_type(o2) == "Vector2" then
        return Vector2.new(o1.x * o2.x, o1.y * o2.y)
    end
    error "Vector2 cannot be multiplied with anything except numbers and other Vector2s"
end
function Vector2:__div(o)
    assert(type(o) == "number" or custom_type(o) == "Vector2", "Vector2 cannot be divided by anything except numbers and Vector2s")
    if type(o) == "number" then
        return Vector2.new(self.x / o, self.y / o)    
    end
    return Vector2.new(self.x / o.x, self.y / o.y)
end
function Vector2:__tostring()
    return "{"..tostring(self.x)..", "..tostring(self.y).."}"
end

-- returns new Vector2; default values are 0
function Vector2.new(x, y)
    local x, y = x or 0, y or 0
    local v = {x=x, y=y, X=x, Y=y}
    v.Magnitude = math.sqrt(x * x + y * y)
    v.magnitude = v.Magnitude
    v.Unit = v
    if v.Magnitude == 1 then
        v.Unit = v
    elseif v.Magnitude > 0 then
        v.Unit = Vector2.new(x / v.Magnitude, y / v.Magnitude)
    end
    v.unit = v.Unit
    local alias = {__true = v}
    setmetatable(alias, Vector2)
    return alias
end
-- returns new Vector2 using angle and magnitude; optional Degrees if angle is in degrees instead of radians
function Vector2.fromAngle(angle, magnitude, Degrees)
    local angle = angle
    if Degrees then angle = math.rad(angle) end
    local magnitude = magnitude or 1
    return Vector2.new(math.cos(angle) * magnitude, math.sin(angle) * magnitude)
end
-- returns a new Vector2 rotated by amount angle; optional Degrees if angle is in degrees instead of radians
function Vector2:Rotate(angle, Degrees)
    local angle = angle
    if Degrees then angle = math.rad(angle) end
    local currentAngle = math.atan2(self.y, self.x)
    return Vector2.fromAngle(angle + currentAngle, self.Magnitude)
end
-- returns the distance between self and the given Vector2
function Vector2:distanceTo(v)
    assert(custom_type(v) == "Vector2", "arg v must be another Vector2")
    return (self - v).Magnitude
end
-- returns scalar dot product of self and the given Vector2
function Vector2:Dot(v)
    return self.x * v.x + self.y * v.y
end
-- returns Vector2 of reflection against surface with normal n
function Vector2:Reflect(n)
    return self - 2 * self:Dot(n) * n
end
-- returns number Angle between two Vector2s in radians
function Vector2:angleBetween(v)
    return math.acos(self.Unit:Dot(v.Unit))
end
-- returns Vector2 of self projected onto other
function Vector2:Project(other)
    --return self:Dot(other) / other.Magnitude^2 * other
    --return self.Magnitude * math.cos(self:angleBetween(other)) * other
    return self:Dot(other.Unit) * other.Unit
end
-- returns Vector2 of interpolation between self and v with weight a
function Vector2:Lerp(v, a)
    local a = math.max(0, math.min(a, 1))
    if a == 0 then
        return Vector2.new(self.x, self.y)
    elseif a == 1 then
        return Vector2.new(v.x, v.y)
    end
    return self * (1 - a) + v * a
end
Vector2.ZERO = Vector2.new()

return Vector2