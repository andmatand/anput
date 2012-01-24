require 'class/navigator.lua'
require 'class/floodfiller.lua'

RoomBuilder = {}
RoomBuilder.__index = RoomBuilder

-- A RoomBuilder places bricks inside a room
function RoomBuilder:new(exits)
	local o = {}
	setmetatable(o, self)

	o.exits = exits -- A table of exit positions

	return o
end

-- Returns a table of bricks
function RoomBuilder:build()
	self.bricks = {}
	occupiedTiles = {}

	self:order_exits()

	-- Save positions of doorway tiles at each exit
	doorwayTiles = {}
	for i,e in ipairs(self.exits) do
		dw = e:get_doorways()
		table.insert(doorwayTiles, {x = dw.x1, y = dw.y1})
		table.insert(doorwayTiles, {x = dw.x2, y = dw.y2})
	end

	-- Pick a random point in the middle of the room
	midX = math.random(1, ROOM_W - 2)
	midY = math.random(1, ROOM_H - 2)

	-- Plot paths from all exits to the midpoint
	for i,e in ipairs(self.exits) do
		-- Give doorwayTiles as the only hotLava for this path
		pf = PathFinder:new(e.x, e.y, midX, midY, doorwayTiles)
		tiles = pf:plot()

		-- Append these coordinates to list of illegal coordinates
		for j,b in pairs(tiles) do
			table.insert(occupiedTiles, {x = b.x, y = b.y})
		end
	end

	-- Add doorwayTiles to occupiedTiles
	--for i,d in pairs(doorwayTiles) do
	--	table.insert(occupiedTiles, {x = d.x, y = d.y})
	--end

	-- TEMP: draw tiles as bricks
	table.insert(self.bricks, Brick:new(midX, midY))
	--for j,b in pairs(occupiedTiles) do
	--	table.insert(self.bricks, Brick:new(b.x, b.y))
	--end

	-- Make wall from right doorway of each exit to left doorway of next exit
	for i,e in ipairs(self.exits) do
		print('\nexit ' .. i)
		dw = e:get_doorways()
		srcX = dw.x2
		srcY = dw.y2

		-- If there is another exit to connect to
		if self.exits[i + 1] ~= nil then
			-- Set the next exit's left doorway as the destination
			destDw = self.exits[i + 1]:get_doorways()
		else
			-- Set the first exit's left doorway as the destination
			destDw = self.exits[1]:get_doorways()
		end
		destX = destDw.x1
		destY = destDw.y1

	--	-- Find all vacant tiles accessible from the source doorway
	--	print(srcX, srcY)
	--	ff = FloodFiller:new(srcX, srcY, occupiedTiles)
	--	freeTiles = ff:flood()
	--	numFreeTiles = len(freeTiles)

	--	-- Pick 1-3 random points in the avaiable space
	--	numPoints = math.random(1, 3)
	--	points = {}
	--	for p = 1,numPoints do
	--		tile = freeTiles[math.random(1, numFreeTiles)] 
	--		table.insert(points, {x = tile.x, y = tile.y})
	--	end
	--	
	--	-- Index the points in the best order
	--	points = RoomBuilder:order_points(srcX, srcY, destX, destY, points)

	--	-- Add all points to a table of destinations
	--	destinations = {}
	--	for p = 1,numPoints do
	--		destinations[p] = {x = points[p].x, y = points[p].y}
	--	end
	--	destinations[numPoints + 1] = {x = destX, y = destY}

	--	for i,d in ipairs(destinations) do
	--		print('destination ' .. i .. ': ' .. d.x .. ',' .. d.y)
	--	end

		-- Plot a path along all points
		--nav = Navigator:new(dw.x2, dw.y2, destinations, occupiedTiles)
		--tiles = nav:plot()

		pf = PathFinder:new(dw.x2, dw.y2, destX, destY, occupiedTiles, true)
		tiles = pf:plot()

		-- Make bricks at these coordinates
		for j,b in pairs(tiles) do
			table.insert(self.bricks, Brick:new(b.x, b.y))
		end
	end

	print('room built')
	return self.bricks
end

function RoomBuilder:order_exits()
	-- Index the exits in clockwise order
	temp = {}
	exitNum = 1

	x = -1
	y = -1
	while true do
		-- Find the next exit on the current edge
		for i,e in pairs(self.exits) do
			-- Top
			if y == -1 and x < ROOM_W then
				if e.y == y and e.x > x then
					x = e.x
					temp[exitNum] = e
					break
				end

			-- Right
			elseif x == ROOM_W and y < ROOM_H then
				if e.x == x and e.y > y then
					y = e.y
					temp[exitNum] = e
					break
				end

			-- Bottom
			elseif y == ROOM_H and x > -1 then
				if e.y == y and e.x < x then
					x = e.x
					temp[exitNum] = e
					break
				end

			-- Left
			elseif x == -1 then
				if e.x == x and e.y < y then
					y = e.y
					temp[exitNum] = e
					break
				end
			end
		end 
		exitNum = exitNum + 1
		
		-- Proceed clockwise to the next edge
		-- Top goes right
		if y == -1 and x < ROOM_W then
			x = ROOM_W

		-- Right goes to bottom
		elseif x == ROOM_W and y < ROOM_H then
			y = ROOM_H

		-- Bottom goes to left
		elseif y == ROOM_H and x > -1 then
			x = -1
		
		-- Left
		elseif x == -1 then
			break
		end
	end

	-- Replace old exit table with indexed version
	self.exits = temp
end

function RoomBuilder:order_points(srcX, srcY, destX, destY, points)
	print('starting order_points()')
	ot = {} -- The new, ordered table
	otSize = 0

	-- TEMP: just return them in any order
	for i,p in pairs(points) do
		ot[i] = p
	end

--	-- Choose x direction for ordering based on x-value
--	if srcX < destX then
--		xDir = 1
--	elseif srcX > destX then
--		xDir = -1
--	else
--		xDir = 0
--	end
--
--	if xDir ~= 0 then
--		-- Order based on x-value
--		if xDir == 1 then
--			prevX = 0
--		else
--			prevX = ROOM_W - 1
--		end
--		while true do
--			for i,p in ipairs(points) do
--				if (xDir == 1 and p.x >= prevX) or
--				   (xDir == -1 and p.x <= prevX) then
--					prevX = p.x
--
--					-- Add this point to the ordered table
--					otSize = otSize + 1
--					ot[otSize] = table.remove(points, i)
--					break
--				end
--			end
--
--			if len(points) == 0 then break end
--		end
--	end
--
--	print('done')
	return ot
end
