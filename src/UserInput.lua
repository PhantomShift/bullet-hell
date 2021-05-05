local BindableEvent = require "BindableEvent"

local UserInput = {
    MouseButtonPressed = BindableEvent.new(),
    KeyPressed = BindableEvent.new()
}

function love.keypressed(key)
    UserInput.KeyPressed:Fire(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    UserInput.MouseButtonPressed:Fire(button, x, y)
end

return UserInput