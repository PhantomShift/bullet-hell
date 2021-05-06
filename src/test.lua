local Instance = require "Instance"
local taskscheduler = require "taskscheduler"
local statemanager = require "statemanager"
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
    statemanager.SetState("Main")
end)

test.state = statemanager.CreateState("test", function() test_thread.update() end, test.draw, test_thread)

return test