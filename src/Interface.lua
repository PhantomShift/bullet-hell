local Vector2 = require "Vector2"
local BindableEvent = require "BindableEvent"
local Vector2 = require "Vector2"
local Instance = require "Instance"
local UserInput = require "UserInput"
local geometry = require "geometry"

-- Module for creating and managing user interfaces based on a parent-child structure with bindings for events for functionality
local Interface = Instance:extend("Interface", {
    -- Methods
    -- Calculates the actual size in pixels
    GetAbsoluteSize = function(self)
        local parent = self.Parent
        local pSize = parent and parent:GetAbsoluteSize() or Vector2.new(love.graphics.getWidth(), love.graphics.getHeight())
        return Vector2.new(pSize.X * self.Size.Percent.X + self.Size.Offset.X, pSize.Y * self.Size.Percent.Y + self.Size.Offset.Y)
    end,
    GetAbsolutePosition = function(self)
        local parent = self.Parent
        local pPosition = parent and parent:GetAbsolutePosition() or Vector2.ZERO
        local pSize = parent and parent:GetAbsoluteSize() or Vector2.new(love.graphics.getWidth(), love.graphics.getHeight())
        local sSize = self:GetAbsoluteSize()
        return Vector2.new(pPosition.X + pSize.X * self.Position.Percent.X + self.Position.Offset.X - self.AnchorPoint.X * sSize.X, pPosition.Y + pSize.Y * self.Position.Percent.Y + self.Position.Offset.Y - self.AnchorPoint.Y * sSize.Y)
    end,
    SetSize = function(self, xPer, yPer, xOffset, yOffset)
        self.Size = {Percent = Vector2.new(xPer, yPer), Offset = Vector2.new(xOffset, yOffset)}
    end,
    SetPosition = function(self, xPer, yPer, xOffset, yOffset)
        self.Position = {Percent = Vector2.new(xPer, yPer), Offset = Vector2.new(xOffset, yOffset)}
    end,
    Draw = function(self)
        local parent = self.Parent
        if not parent and not self.FORCEDRAW then return end
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(self.Color.R, self.Color.G, self.Color.B, 1 - self.Transparency)
        local size = self:GetAbsoluteSize()
        local pos = self:GetAbsolutePosition()
        love.graphics.rectangle("fill", pos.X, pos.Y, size.X, size.Y)
        love.graphics.setColor(r,g,b,a)
    end,
    __constructor = function(t)
        -- Properties
        t.Position = {Offset = Vector2.new(), Percent = Vector2.new()}
        t.Size = {Offset = Vector2.new(), Percent = Vector2.new()}
        t.AnchorPoint = Vector2.new()
        t.Transparency = 0
        t.Rotation = 0
        t.Color = {R = 1, G = 1, B = 1}

        -- Events
        t.OnClicked = BindableEvent.new()
        UserInput.MouseButtonPressed:Connect(function(button, x, y)
            if button == 1 then
                local size, pos = t:GetAbsoluteSize(), t:GetAbsolutePosition()
                if geometry.PointVsRectangle(geometry.Shapes.Rectangle.new(pos.X, pos.Y, size.X, size.Y), Vector2.new(x,y)) then
                    t.OnClicked:Fire()
                end
            end
        end)
    end,
    Update = function(self)

    end
})

local root = Instance.new("Interface")
root.Size.Percent = Vector2.new(0.5, 0.5)
root.Size.Offset = Vector2.new(-10, -10)
root.Color = {R=0,G=0,B=0}
root.FORCEDRAW = true
root.OnClicked:Connect(function()
    root.Color = {R=math.random(),G=math.random(),B=math.random()}
end)

Interface.ROOT = root

return Interface