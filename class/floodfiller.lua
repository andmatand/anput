FloodFiller = {}
FloodFiller.__index = FloodFiller

-- A FloodFiller finds all tiles accessible from x, y which are neither hotLava
-- nor outside the bounds of the room.
-- Returns a table of coordinates
function FloodFiller:new(x, y, hotLava)
	local o = {}
	setmetatable(o, self)

	o.x = x
	o.y = y
	o.hotLava = hotLava -- Coordinates which are illegal to traverse

	return o
end

function FloodFiller:flood()
	self.nodes = {}
	self.nodes = self:search()

	return self.nodes
end

function FloodFiller:search()
	print('starting floodfiller search()')

	found = {}
	used = {}

	-- Add the source position as the first node
	table.insert(found, {x = self.x, y = self.y})

	while #found > 0 do
		-- Pop the last node off the table found nodes
		currentNode = found[#found]
		table.insert(used, table.remove(found, #found))

		-- Investigate the (non-diagonal) surroundings
		for d = 1,4 do
			if d == 1 then
				-- North
				x = currentNode.x
				y = currentNode.y - 1
			elseif d == 2 then
				-- East
				x = currentNode.x + 1
				y = currentNode.y
			elseif d == 3 then
				-- South
				x = currentNode.x
				y = currentNode.y + 1
			elseif d == 4 then
				-- West
				x = currentNode.x - 1
				y = currentNode.y
			end

			if self:legal_position(x, y) then
				alreadyFound = false
				for i,n in pairs(found) do
					if x == n.x and y == n.y then
						alreadyFound = true
						break
					end
				end
				for i,n in pairs(used) do
					if x == n.x and y == n.y then
						alreadyFound = true
						break
					end
				end

				-- Add these coordinates to the table of found nodes
				if not alreadyFound then
					table.insert(found, {x = x, y = y})
				end
			end
		end
	end

	print('done')
	return used
end

function FloodFiller:legal_position(x, y)
	-- If this tile is outside the bounds of the room
	if x < 0 or x > ROOM_W - 1 or y < 0 or y > ROOM_H - 1 then
		return false
	end

	-- If this is an illegal tile
	if self.hotLava ~= nil then
		for i,b in pairs(self.hotLava) do
			if x == b.x and y == b.y then
				return false
			end
		end
	end

	return true
end
