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
	self.tiles = {}
	self:search()

	return self.tiles
end

function FloodFiller:search()
	x = self.x
	y = self.y
	numTiles = 0
	print('starting floodfiller search()')

	xDir = -1 -- West
	yDir = -1 -- North
	movedY = false
	while true do
		if movedY == false then
			x = x + xDir
		end

		if self:tile_vacant(x, y) then
			movedY = false
			numTiles = numTiles + 1
			self.tiles[numTiles] = {x = x, y = y}
		else
			if movedY == false then 
				if xDir == -1 then
					-- Switch to east
					x = self.x
					xDir = 1
				elseif xDir == 1 then
					-- Move y and reset xDir to west
					y = y + yDir
					movedY = true
					xDir = -1
				end
			else
				movedY = false
				if yDir == -1 then
					-- Switch to south
					movedY = true
					yDir = 1
					y = self.y + 1
					x = self.x
					xDir = -1
				else
					-- We're done
					break
				end
			end
		end
	end
	print('done')
end

function FloodFiller:tile_vacant(x, y)
	-- If this tile is hotLava
	for i,t in pairs(self.hotLava) do
		if x == t.x and y == t.y then
			return false
		end
	end

	-- If this tile is outside the bounds of the room
	if x < 0 or x > ROOM_W - 1 or y < 0 or y > ROOM_H - 1 then
		return false
	end

	return true
end
