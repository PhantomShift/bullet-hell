local Instance = require "Instance"
local taskscheduler = require "taskscheduler"
local ROOT = Instance.new("Interface")
ROOT.FORCEDRAW = true
ROOT:SetSize(1, 1, 0, 0)
ROOT.OnClicked:Connect(function()
    ROOT.Color = {R=math.random(),G=math.random(),B=math.random()}
end)

local test_thread = taskscheduler.new("test")

local test = {}

function test.draw()
    ROOT:Draw()
end

test_thread.delay(10, function()
    test_thread.Paused = true
    taskscheduler.schedulers.main.Paused = false
    love.draw = test.oldDraw
end)

return test