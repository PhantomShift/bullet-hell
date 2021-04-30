local connection_mt = {
    Disconnect = function(self)
        self.Owner.__connections[self] = nil
    end
}
connection_mt.__index = connection_mt
connection_mt.__newindex = function(self, index) error("No propery "..tostring(index).." in Connection") end

-- Custom event management class; connections are run in a separate thread
local BindableEvent = {
    Connect = function(self, func)
        local connection = {Owner = self, Coroutine = coroutine.wrap(func)}
        setmetatable(connection, connection_mt)
        self.__connections[connection] = true
        return connection
    end,
    Fire = function(self, ...)
        for connection, _ in pairs(self.__connections) do
            connection.Coroutine(...)
        end
    end
}
function BindableEvent:__index(index)
    if self.__connections[index] then
        return self.__connections[index]
    end
    return BindableEvent[index]
end
function BindableEvent.new()
    return setmetatable({__connections = {}}, BindableEvent)
end

return BindableEvent