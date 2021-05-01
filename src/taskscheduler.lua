local BindableEvent = require "BindableEvent"
local coroutine = require "coroutine"
local tick = os.clock

local frametime = 1/60
local __await = {}
local __time = tick()
local taskscheduler = {
    Stepped = BindableEvent.new(),
    Paused = false
}

local main_thread = coroutine.create(function()
    while true do
        local currentTime = tick()
        local dt = currentTime - __time
        if taskscheduler.Paused then
            __time = currentTime
            for c, delay in pairs(__await) do
                __await[c] = delay + dt
            end
        else
            if dt > frametime then
                taskscheduler.Stepped:Fire(dt)
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

function taskscheduler.update()
    local success, err = coroutine.resume(main_thread)
    if not success then
        error(table.concat({"Thread error from", tostring(main_thread), ":", err}))
    end
end

-- Note that a delay of 0 is practically just spawning a thread; if simply spawning a new thread is desired, consider using coroutine.wrap
function taskscheduler.delay(delay, func, ...)
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

return taskscheduler