local BindableEvent = require "BindableEvent"
local coroutine = require "coroutine"
local tick = os.clock

local frametime = 1/60
local taskscheduler = {
    schedulers = {}
}
function taskscheduler.new(name)
    local __await = {}
    local __time = tick()
    local scheduler = {
        Stepped = BindableEvent.new(),
        Paused = false,
        Name = name
    }
    local thread = coroutine.create(function()
        while true do
            local currentTime = tick()
            local dt = currentTime - __time
            if scheduler.Paused then
                __time = currentTime
                for c, delay in pairs(__await) do
                    __await[c] = delay + dt
                end
            else
                if dt > frametime then
                    scheduler.Stepped:Fire(dt)
                    __time = currentTime
                end
                for c, delay in pairs(__await) do
                    if currentTime > delay then
                        local s, e = coroutine.resume(c)
                        if not s then error(e) end
                        __await[c] = nil
                    end
                end
            end
            coroutine.yield()
        end
    end)
    function scheduler.update()
        --print(coroutine.status(thread))
        if coroutine.status(thread) == "running" or coroutine.status(thread) == "normal" then return end
        local success, err = coroutine.resume(thread)
        if not success then
            error(table.concat({"Thread error from", name, ":", err}))
        end
    end
    function scheduler.delay(delay, func, ...)
        local delay = delay or 0
        if delay < 0 then delay = 0 end 
        local t = {...} or nil
        local c
        if t then
            c = coroutine.create(function() func(unpack(t)) end)
        else
            c = coroutine.create(func)
        end
        __await[c] = delay + tick()
    end
    taskscheduler.schedulers[name] = scheduler
    return scheduler
end

taskscheduler.schedulers.main = taskscheduler.new("main")


return taskscheduler