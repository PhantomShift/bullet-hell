local taskscheduler = require "taskscheduler"

local statemanager = {
    __states = {},
    CurrentState = nil
}
function statemanager.SetState(stateName)
    local state = statemanager.__states[stateName]
    assert(state, "State not found")
    if statemanager.CurrentState then
        statemanager.CurrentState.scheduler.Paused = true
    end
    statemanager.CurrentState = state
    love.update, love.draw = state.update, state.draw
    state.scheduler.Paused = false
end
function statemanager.GetState()
    return statemanager.CurrentState
end
function statemanager.CreateState(name, update, draw, scheduler)
    local state = {
        name = name,
        update = update,
        draw = draw,
        scheduler = scheduler
    }
    statemanager.__states[name] = state
    return state
end

return statemanager