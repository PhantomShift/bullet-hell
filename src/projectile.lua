local Vector2 = require "Vector2"
local geometry = require "geometry"
local player = require "player"
local Shapes = geometry.Shapes

local projectile = {}
projectile.__index = projectile
projectile.ProjectileList = {}
function projectile:Destroy()
    projectile.ProjectileList[self] = nil
end

function projectile.laser(start, direction, flags)
    local boundary_box = Shapes.Rectangle.new(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    local initial = geometry.RayVsRect(start, direction, boundary_box, true)
    local segments = {{start = start, direction = direction, stop = initial.Point + initial.Normal * Vector2.new(1, -1), normal = initial.Normal}}
    if flags and flags.reflections then
        for i = 1, flags.reflections do
            --print "Hey reflected off a surface"
            local prev = segments[i]
            local intersect = geometry.RayVsRect(prev.stop, prev.direction:Reflect(prev.normal * Vector2.new(1, -1)), boundary_box, true)
            --print(intersect.Point)
            --print(prev.start, prev.stop, prev.normal, prev.direction, prev.direction:Reflect(prev.normal * Vector2.new(1, -1)))
            table.insert(segments, {
                start = prev.stop,
                direction = prev.direction:Reflect(prev.normal * Vector2.new(1, -1)),
                stop = intersect.Point + prev.normal * Vector2.new(1, -1),
                normal = intersect.Normal
            })
        end
    end
    local function draw(self)
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(1, 0, 0, math.max(self.lifetime - self.time, 0.2))
        for i, segment in pairs(segments) do
            local str, stp = segment.start, segment.stop
            love.graphics.line(str.x,str.y,stp.x,stp.y)
            love.graphics.circle("line", str.x, str.y, 10)
            love.graphics.circle("line", stp.x, stp.y, 10)
        end
        love.graphics.setColor(r,g,b,a)
    end
    local function update(self, elapsedTime)
        self.time = self.time + elapsedTime
        if self.time > self.lifetime then
            self:Destroy()
        end
    end
    -- assumes "target" is a circle
    local function hits(self, target)
        for i, segment in pairs(segments) do
            if geometry.CheckRayVsCircle(segment.start, segment.stop, target) then
                return true
            end
        end
        return false
    end
    local laser = {segments = segments, draw = draw, update = update, hits = hits, time = 0, lifetime = flags and flags.lifetime or 2}
    setmetatable(laser, projectile)
    projectile.ProjectileList[laser] = true
    return laser
end

-- note that this is coded specifically for enemy projectiles
local WeakHomingProjectiles = {
    update = function(self, elapsedTime)
        if self.pos.y > love.graphics.getHeight() then
            self:Destroy()
            return
        elseif self.pos.y < player.pos.y then
            self.vel = self.vel + (player.pos - self.pos).Unit * self.strength * elapsedTime
        end
        self.pos = self.pos + self.vel * elapsedTime
    end
}
WeakHomingProjectiles.__index = WeakHomingProjectiles
setmetatable(WeakHomingProjectiles, projectile)
function projectile.weakHomingCircle(pos, vel, radius, strength)
    local homing = {pos = pos, vel = vel, radius = radius or 10, strength = strength or 100}
    function homing.getHitbox()
        return geometry.Shapes.Circle.new(homing.pos.x, homing.pos.y, homing.radius)
    end
    function homing:hits(hitbox)
        return geometry.CheckCircleVsCircle(homing.getHitbox(), hitbox)
    end
    function homing:draw(color)
        local r1, g1, b1, a1 = 0,0,0,1
        if color then r1, g1, b1, a1 = unpack(color) end
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(r1,g1,b1,a1)
        love.graphics.circle("line", homing.pos.x, homing.pos.y, homing.radius)
        love.graphics.setColor(r,g,b,a)
    end
    setmetatable(homing, WeakHomingProjectiles)
    projectile.ProjectileList[homing] = true

end

return projectile