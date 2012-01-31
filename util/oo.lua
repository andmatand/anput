function class()
	local newClass = {}
	newClass.__index = newClass

	-- A Game handles a collection of rooms
	function newClass:new()
		local o = {}
		setmetatable(o, self)

		return o
	end

	return newClass
end

-- Create a new class that inherits from a base class
function inherit_class(baseClass)
    -- Create the table and metatable representing the class.
    local newClass = {}
    local class_mt = {__index = newClass}

    -- Note that this function uses class_mt as an upvalue, so every instance
    -- of the class will share the same metatable.
    function newClass:new()
		local newinst = {}
        setmetatable(newinst, class_mt)
        return newinst
    end

    -- The following is the key to implementing inheritance:

    -- The __index member of the new class's metatable references the
    -- base class.  This implies that all methods of the base class will
    -- be exposed to the sub-class, and that the sub-class can override
    -- any of these methods.
    if baseClass then
        setmetatable(newClass, {__index = baseClass})
    end

    return newClass
end
