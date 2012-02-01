-- A FloodFiller finds all tiles accessible from x, y which are neither hotLava
-- nor outside the bounds of the room.
-- Returns a table consisting of:
--   freeTiles: a table of coordinates of free tiles
--   hotLava: the same a table of coordinates that was passed in as a
--            parameter, with an extra key on each element denoting whether it
--            was touched (including by diagonal searching, which freeTiles
--            does not use) e.g. {x = 17, y = 3, touched = true}

FloodFiller = class()

function FloodFiller:init(source, hotLava)
	self.source = source -- Needs to have and x and y key, e.g. {x = 2, y = 47}
	self.hotLava = hotLava -- Coordinates which are illegal to traverse
end

function FloodFiller:flood()
	found = {}
	used = {}

	-- Add the source position as the first node
	table.insert(found, self.source)

	while #found > 0 do
		-- Pop the last node off the table found nodes
		currentNode = found[#found]
		table.insert(used, table.remove(found, #found))

		-- Investigate the non-diagonal surroundings
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

		-- Search the diagonals only to mark hotLava tiles as touched
		if math.random(0, 2) == 0 then
			for d = 1,4 do
				if d == 1 then
					-- NE
					x = currentNode.x + 1
					y = currentNode.y - 1
				elseif d == 2 then
					-- SE
					x = currentNode.x + 1
					y = currentNode.y + 1
				elseif d == 3 then
					-- SW
					x = currentNode.x - 1
					y = currentNode.y + 1
				elseif d == 4 then
					-- NW
					x = currentNode.x - 1
					y = currentNode.y - 1
				end

				for i,l in pairs(self.hotLava) do
					if x == l.x and y == l.y then
						l.touched = true
					end
				end
			end
		end
	end

	-- Remove the starting node
	table.remove(used, 1)
	return {freeTiles = used, hotLava = self.hotLava}
end

function FloodFiller:legal_position(x, y)
	-- If this tile is outside the bounds of the room
	if x < 0 or x > ROOM_W - 1 or y < 0 or y > ROOM_H - 1 then
		return false
	end

	-- If this is an illegal tile
	if self.hotLava ~= nil then
		for i,l in pairs(self.hotLava) do
			if x == l.x and y == l.y then
				l.touched = true
				return false
			end
		end
	end

	return true
end
