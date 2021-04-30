local Vector2 = require "Vector2"

local camera = {
    -- The draw function that should be used for any drawable objects that need to be moved relative to the camera
    Draw = function(drawable, posX, posY, rotation, scaleX, scaleY, offsetX, offsetY)
        local posX = posX or 0
        local posY = posY or 0
        local scaleX = scaleX or 1
        local scaleY = scaleY or 1
        love.graphics.draw(drawable,posX,posY,rotation,scaleX,scaleY,offsetX,offsetY)
    end,
    Translate = function(self)
        love.graphics.scale(self.getScale(), self.getScale())
        love.graphics.translate(self.getPosition().X, self.getPosition().Y)
    end,
    isPointVisible = function(self, posX, posY)
        local cameraPos = self.getPosition()
        local cameraScale = self.getScale()
        return (posX > cameraPos.X * cameraScale() and posX < (cameraPos().X + love.graphics.getWidth())) and (posY > cameraPos().Y * cameraPos and posY < (cameraPos().Y + love.graphics.getHeight) * cameraPos)
    end,
    isRectangleVisible = function(self, posX, posY, widthX, widthY)
        local cameraPos = self.getPosition()
        local cameraScale = self.getScale()
        local r =(posX > cameraPos.X * cameraScale and posX + widthX < (cameraPos.X + love.graphics.getWidth()) * cameraScale)
        print(r)
    end
}
camera.__index = camera

-- Class that handles transformation and scaling of drawable objects which are drawn relative to the viewing area
function camera.new(posX, posY, scale)
    local t = {}
    local Scale = scale or 1
    local Position = Vector2.new(posX, posY)
    function t.getPosition()
        return Position
    end
    function t.setPosition(v)
        assert(getmetatable(v) and getmetatable(v).__type == "Vector2", "Position must be a Vector2")
        Position = v
    end
    function t.getScale()
        return Scale
    end
    function t.setScale(n)
        assert(type(n) == "number" and n > 0, "Scale must be a number greater than 0")
        Scale = n
    end
    setmetatable(t, camera)
    return t
end

return camera