local Vector2 = require "Vector2"
local geometry = require "geometry"
local taskscheduler = require "taskscheduler"
local player = require "player"
local path = require "path"
local Shapes = geometry.Shapes

local projectile = {
    __tostring = function(self)
        return self.__type or "Projectile"
    end
}
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
    local laser = {segments = segments, draw = draw, update = update, hits = hits, time = 0, lifetime = flags and flags.lifetime or 2, __type = "Laser"}
    setmetatable(laser, projectile)
    projectile.ProjectileList[laser] = true
    return laser
end

-- note that this is coded specifically for enemy projectiles
local WeakHomingProjectiles = {
    __type = "Weaking Homing Projectile",
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

local function distance_from_player(posx,posy)
    --local playerx, playery = player.pos_x, player.pos_y
    --return math.sqrt((playerx - posx) * (playerx - posx) + (playery - posy) * (playery - posy))
    return player.center():distanceTo(Vector2.new(posx, posy))
end
local GravityBoundProjectile = {
    __type = "Gravity Bound Projectile",
    draw = function(self)
        if not projectile.ProjectileList[self] then return end
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(0,0,0)
        love.graphics.circle("fill",self.pos.x,self.pos.y,self.radius)
        love.graphics.setColor(r,g,b,a)
    end,
    update = function(self, elapsedTime)
        self.vel = Vector2.new(self.vel.x, self.vel.Y - GRAVITY * elapsedTime)
        self.pos = self.pos + self.vel * elapsedTime
        if self.pos.y > Y_MAX then
            projectile.ProjectileList[self] = false
            return
        end
    end,
    hits = function(self, hitbox)
        if not projectile.ProjectileList[self] then return false end
        return distance_from_player(self.pos.x, self.pos.y) < 50 and geometry.CheckCircleVsCircle(hitbox, Shapes.Circle.new(self.pos.x, self.pos.y, self.radius))
    end
}
GravityBoundProjectile.__index = GravityBoundProjectile
function projectile.gravityBoundCircle(posX, posY, velX, velY, radius)
    local c = {
        pos = Vector2.new(posX, posY),
        vel = Vector2.new(velX or math.random(-50, 50), velY or math.random(0, 50)),
        radius = radius or 10
    }
    setmetatable(c, GravityBoundProjectile)
    projectile.ProjectileList[c] = true
    return c
end

function projectile.spiralCircle(pos, rotSpeed, expSpeed, startAngle, radius)
    local t = {draw = GravityBoundProjectile.draw, hits = GravityBoundProjectile.hits, lifetime = 0, pos = pos, radius = radius or 10, __type = "Spiral"}
    local resolve = path.Spiral(pos, rotSpeed, expSpeed, startAngle)
    function t:update(elapsedTime)
        self.lifetime = self.lifetime + elapsedTime
        local p, r = resolve(self.lifetime)
        if r > love.graphics.getHeight() then
            projectile.ProjectileList[t] = nil
            return
        end
        self.pos = p
    end
    setmetatable(t, projectile)
    projectile.ProjectileList[t] = true
    return t
end

function projectile.delayedChase(pos, target, delay, initialVelocity, chaseSpeed, radius)
    local chase = {draw = GravityBoundProjectile.draw, hits = GravityBoundProjectile.hits, lifetime = 0, pos = pos, radius =  radius or 10, vel = initialVelocity, __type = "Delayed Chase"}
    function chase:update(elapsedTime)
        self.vel = self.vel:Lerp(Vector2.ZERO, elapsedTime)
        self.pos = self.pos + self.vel * elapsedTime
    end
    taskscheduler.schedulers.main.delay(delay, function()
        chase.vel = (target:center() - chase.pos).Unit * chaseSpeed
        chase.update = function(self, elapsedTime)
            if not projectile.ProjectileList[self] then return end
            self.pos = self.pos + self.vel * elapsedTime
            if self.pos.x < 0 or self.pos.y < 0 or self.pos.x > love.graphics.getWidth() or self.pos.y > love.graphics.getHeight() then
                projectile.ProjectileList[self] = false
            end
        end
    end)
    setmetatable(chase, projectile)
    projectile.ProjectileList[chase] = true
    return chase
end

return projectile