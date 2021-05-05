
-- Base class for parent-child intheritance-based objects; inspired by Roblox's class system
local Instance = {
    __classes = {},
    __class = true,
    Name = "Instance",
    ClassName = "Instance",
    GetChildren = function(self)
        table.sort(self.__children, function (a, b)
            return a.Name < b.Name
        end)
    end,
    FindFirstChild = function(self, name)
        assert(name, "No name provided")
        for i, child in pairs(self:GetChildren()) do
            if child.Name == name then
                return child
            end
        end
        return nil
    end,
    IsA = function(self, className)
        return self.ClassName == className
    end,
}

-- For creating new classes under Instance
function Instance:extend(ClassName, t)
    assert(ClassName, "No ClassName provided for class definition")
    local t = t or {}
    t.ClassName = ClassName
    self.__index = self
    t.__index = t
    setmetatable(t, self)
    Instance.__classes[ClassName] = t
    return t
end

-- Overarching constructor for new instances
function Instance.new(ClassName, Parent)
    local class = Instance.__classes[ClassName]
    assert(class, "No valid class was given to Instance.new")
    assert(class.__constructor, "Class has no constructor method")
    local t = {Name = ClassName, Parent = Parent, __class = false, __children = {}}
    if Parent then
        table.insert(Parent.__children, t)
    end
    setmetatable(t, class)
    class.__constructor(t)
    return t
end

return Instance