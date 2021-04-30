-- Task scheduler that manages all COROUTINES that rely on some sort of time delay
local taskscheduler = {__tasks = {}}
function taskscheduler.addTask(Coroutine, Lifetime)
    taskscheduler.__tasks[{Coroutine = Coroutine, Lifetime = Lifetime}] = 0
end
function taskscheduler.update(elapsedTime)
    for c, t in pairs(taskscheduler.__tasks) do
        t = t + elapsedTime
        --print(t)
        if t > c.Lifetime then
            c.Coroutine()
            --print(c.Coroutine, c.Lifetime)
            taskscheduler.__tasks[c] = nil
        else
            taskscheduler.__tasks[c] = t
        end
    end
end

return taskscheduler