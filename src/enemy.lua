local Vector2 = require "Vector2"
local geometry = require "geometry"
X_MAX = love.graphics.getWidth()
Y_MAX = love.graphics.getHeight()

local placeholder = love.graphics.newImage("assets/matsuri_derp.png")
local enemy = {
    __enemy_list = {},
    __defaults = {
        pos = Vector2.new(love.graphics.getWidth()/2, love.graphics.getHeight()/2),
        size = Vector2.new(placeholder:getWidth()/2, placeholder:getHeight()/2),
    },
    center = function(self)
        return self.pos + self.size / 2
    end,
    getHitbox = function(self)
        return geometry.Shapes.Rectangle.fromVectors(self.pos, self.size)
    end,
    image = placeholder,
    update = function(self, elapsedTime)
        self.pos_x = self.pos_x + 50 * math.random() * math.random(-1,1) * elapsedTime
        self.pos_y = self.pos_y + 50 * math.random() * math.random(-1,1) * elapsedTime
    end,
    draw = function(self)
        if not self.__enemy_list[self] then return end
        --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
        love.graphics.draw(
            self.image,
            self.pos.x,
            self.pos.y,
            0, 0.5, 0.5
        )
        --love.graphics.circle("fill", self.pos_x, self.pos_y, 30)
        local h = self:getHitbox()
        local s = h:Size()
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(1,0.5,0)
        love.graphics.rectangle("line", h.Position.x, h.Position.y, s.x, s.y)
        love.graphics.setColor(r,g,b,a)
    end
}
enemy.__index = enemy
function enemy:new(t)
    local t = t or {}
    for key, value in pairs(self.__defaults) do
        if not t[key] then t[key] = value end
    end
    assert(t.pos, "enemy:new missing arguments")
    self.__index = self
    setmetatable(t, self)
    t.size = Vector2.new(t.image:getWidth()/2, t.image:getHeight()/2)
    enemy.__enemy_list[t] = true
    return t
end


return enemy