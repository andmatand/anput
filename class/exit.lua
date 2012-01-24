Exit = {}
Exit.__index = Exit

function Exit:new(x, y)
	local o = {}
	setmetatable(o, self)

	-- X and Y coordinates
	o.x = x
	o.y = y

	return o
end

function Exit:get_doorways()
	-- Top
	if self.y == -1 then
		x1 = self.x - 1
		y1 = self.y + 1
		x2 = self.x + 1
		y2 = y1

	-- Right
	elseif self.x == ROOM_W then
		x1 = self.x - 1
		y1 = self.y - 1
		x2 = x1
		y2 = self.y + 1
	
	-- Bottom
	elseif self.y == ROOM_H then
		x1 = self.x + 1
		y1 = self.y - 1
		x2 = self.x - 1
		y2 = y1

	-- Left
	elseif self.x == -1 then
		x1 = self.x + 1
		y1 = self.y + 1
		x2 = x1
		y2 = self.y - 1
	end

	return {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end
