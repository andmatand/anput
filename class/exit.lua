Exit = {}
Exit.__index = Exit

function Exit:new(x, y)
	local o = {}
	setmetatable(o, self)

	-- X and Y coordinates
	o.x = x
	o.y = y
	--print('new exit at ', x, y)

	return o
end

function Exit:get_doorframes()
	if self.y == -1 then
		-- North
		x1 = self.x - 1
		y1 = self.y + 1
		x2 = self.x + 1
		y2 = y1
	elseif self.x == ROOM_W then
		-- East
		x1 = self.x - 1
		y1 = self.y - 1
		x2 = x1
		y2 = self.y + 1
	elseif self.y == ROOM_H then
		-- South
		x1 = self.x + 1
		y1 = self.y - 1
		x2 = self.x - 1
		y2 = y1
	elseif self.x == -1 then
		-- West
		x1 = self.x + 1
		y1 = self.y + 1
		x2 = x1
		y2 = self.y - 1
	end

	return {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Exit:get_doorway()
	if self.y == -1 then
		-- North
		x = self.x
		y = self.y + 1
	elseif self.x == ROOM_W then
		-- East
		x = self.x - 1
		y = self.y
	elseif self.y == ROOM_H then
		-- South
		x = self.x
		y = self.y - 1
	elseif self.x == -1 then
		-- West
		x = self.x + 1
		y = self.y
	end

	return {x = x, y = y}
end
