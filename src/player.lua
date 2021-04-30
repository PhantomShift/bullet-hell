X_MAX = love.graphics.getWidth()
Y_MAX = love.graphics.getHeight()

local Vector2 = require "Vector2"
local geometry = require "geometry"

function math.clamp(n, min, max)
    return math.max(min, math.min(n, max))
end

local player = {
    --pos_x = love.graphics.getWidth()/2,
    --pos_y = love.graphics.getHeight()/2,
    pos = Vector2.new(love.graphics.getWidth()/2, love.graphics.getHeight()/2),
    image = love.graphics.newImage("assets/calli.png"),
    bullets = {},
    can_fire = true,
    fire_cd = 0,
    fire_cd_max = 0.1,
    hitbox_radius = 7.5
}
player.size = Vector2.new(player.image:getWidth(), player.image:getHeight())

function player.center()
    return player.pos + player.size / 2
end
function player.getHitbox()
    local c = player.center()
    return geometry.Shapes.Circle.new(c.x, c.y, player.hitbox_radius)
end

function player.draw()
    love.graphics.draw(
        player.image,
        player.pos.x,
        player.pos.y,
        0, 1, 1--,
        --player.size.x / 2,
        --player.size.y / 2
    )
    love.graphics.circle("fill", player.center().x, player.center().y, player.hitbox_radius)
end

function player:move(dx, dy)
    -- self.pos_x = player.pos_x + dx
    -- self.pos_y = player.pos_y + dy
    -- self.pos_x = math.min(self.pos_x, X_MAX - self.offset_x)
    -- self.pos_x = math.max(self.pos_x, 0 + self.offset_x)
    -- self.pos_y = math.min(self.pos_y, Y_MAX - self.offset_y)
    -- self.pos_y = math.max(self.pos_y, 0 + self.offset_y)
    self.pos.x = math.clamp(player.pos.x + dx, -self.size.x / 2, X_MAX - self.size.x / 2)
    self.pos.y = math.clamp(player.pos.y + dy, -self.size.y / 2, Y_MAX - self.size.y / 2)
end

local bullet_mt = {
    update = function(self, elapsedTime, enemy)
        self.pos_y = self.pos_y - self.speed * elapsedTime
        self.rotation = (self.rotation + 1000 * elapsedTime) % 360
        if self.pos_y < 0 - 16 then
            player.bullets[self] = nil
        end
        if enemy then
            local enemy_size = Vector2.new(enemy.image:getWidth() / 2, enemy.image:getHeight() / 2)
            local enemy_position = Vector2.new(enemy.pos_x, enemy.pos_y)
            if geometry.CircleVsRectangle(geometry.Shapes.Circle.new(self.pos_x, self.pos_y, 16), enemy:getHitbox()) ~= Vector2.new() then
                enemy.health = enemy.health - 1
                print(enemy.health)
            end
        end
    end,
    draw = function(self)
        --print(self.pos_x, self.pos_y)
        if not player.bullets[self] then return end
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(0,0,0)
        love.graphics.circle("line", self.pos_x, self.pos_y, 16)
        love.graphics.draw(self.image, self.pos_x, self.pos_y, math.rad(self.rotation), 2, 2, 8, 8)
        love.graphics.setColor(r,g,b,a)
    end,
    image = love.graphics.newImage("assets/bullet.png")
}
bullet_mt.__index = bullet_mt
function player.fire_bullet(pos_x, pos_y, speed)
    assert(pos_x and pos_y)
    local speed = speed or 500
    local bullet = {pos_x = pos_x, pos_y = pos_y, speed = speed, rotation = 270}
    setmetatable(bullet, bullet_mt)
    player.bullets[bullet] = true
    return bullet
end

return player