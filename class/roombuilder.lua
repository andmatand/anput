require('brick')
require('navigator')
require('floodfiller')

-- A RoomBuilder places bricks inside a room
RoomBuilder = class('RoomBuilder')

function RoomBuilder:init(exits)
	self.exits = exits -- A table of exit positions
end

function tile_on_border(tile)
	if (tile.x == 0 or tile.x == TILE_W - 1 or
	    tile.y == 0 or tile.y == TILE_H - 1) then
	   return true
   else
	   return false
   end
end

function num_neighbors(tile, otherTiles)
	neighbors = find_neighbors(tile, otherTiles, {countBorders = true})
	num = 0
	for i,n in pairs(neighbors) do
		if n ~= nil then
			num = num + 1
		end
	end
	return num
end

function add_obstacles(freeTiles, occupiedTiles)
	obstacles = {}
	for j = 1, math.random(1, 50) do
		tile = freeTiles[math.random(1, #freeTiles)] 

		ok = true

		-- Don't add the tile if it has more than one occupied neighbor tile
		numNeighbors =
			num_neighbors({x = tile.x, y = tile.y}, occupiedTiles) + 
			num_neighbors({x = tile.x, y = tile.y}, obstacles)

		--if num_neighbors({x = tile.x, y = tile.y}, occupiedTiles) > 1 then
		if numNeighbors > 1 then
			ok = false
		end

		if ok then
			-- Add this tile to occupiedTiles
			table.insert(obstacles, {x = tile.x, y = tile.y})
		end
	end

	return obstacles
end

-- Returns a table of bricks
function RoomBuilder:build()
	self.bricks = {}
	occupiedTiles = {}

	--self:order_exits()
	print('building room with ' .. #self.exits .. ' exits')

	-- Save positions of doorframe tiles at each exit
	doorframeTiles = {}
	for i,e in ipairs(self.exits) do
		df = e:get_doorframes()
		table.insert(doorframeTiles, {x = df.x1, y = df.y1})
		table.insert(doorframeTiles, {x = df.x2, y = df.y2})
	end

	-- Pick a random point in the middle of the room
	midPoint = {x = math.random(1, ROOM_W - 2), y = math.random(1, ROOM_H - 2)}

	-- Plot paths from all exits to the midpoint
	for i,e in ipairs(self.exits) do
		-- Give doorframeTiles as the only hotLava for this path
		pf = PathFinder(e, midPoint, doorframeTiles)
		tiles = pf:plot()

		-- Append these coordinates to list of illegal coordinates
		for j,b in pairs(tiles) do
			table.insert(occupiedTiles, {x = b.x, y = b.y})
			--table.insert(midPath, {x = b.x, y = b.y}) -- DEBUG
		end
	end

	-- Make wall from right doorframe of each exit to left doorframe of next
	-- exit
	for i,e in ipairs(self.exits) do
		df = e:get_doorframes()
		src = {x = df.x2, y = df.y2}

		-- If there is another exit to connect to
		if self.exits[i + 1] ~= nil then
			-- Set the next exit's left doorframe as the destination
			destdf = self.exits[i + 1]:get_doorframes()
		else
			-- Set the first exit's left doorframe as the destination
			destdf = self.exits[1]:get_doorframes()
		end
		dest = {x = destdf.x1, y = destdf.y1}

		-- Find all vacant tiles accessible from the source doorframe
		ff = FloodFiller(src, occupiedTiles)
		freeTiles = ff:flood().freeTiles

		-- Remove src and dest from freeTiles
		for j,t in pairs(freeTiles) do
			if t.x == dest.x and t.y == dest.y then
				table.remove(freeTiles, j)
				break
			end
		end

		-- Turn some random free tiles into occupied tiles to spice up the
		-- pathfinding a bit
		--obstacles = add_obstacles(freeTiles, occupiedTiles)

		---- Remove illegal tiles from occupiedTiles
		--for j,t in pairs(obstacles) do
		--	ok = true

		--	if distance(t, src) < 4 or distance(t, dest) < 4 then
		--		print('removed obstacle:', t.x, t.y)
		--		ok = false
		--	end
		--		
		--	if ok then
		--		table.insert(occupiedTiles, t)
		--		table.insert(globalObstacles, t) -- DEBUG
		--	end
		--end

		---- Plot a path from around the occupied tiles
		--pf = PathFinder:new(src, dest, occupiedTiles, nil, {smooth = true})
		--tiles = pf:plot()

		-- Pick a random intermediate point for this wall's path
		destinations = {}
		while #destinations == 0 and #freeTiles > 0 do
			tile = freeTiles[math.random(1, #freeTiles)] 

			ok = true
			-- Don't pick points that overlap with src or dest
			if (tile.x == src.x and tile.y == src.y) or
			   (tile.x == dest.x and tile.y == dest.y) then
				ok = false
			end

			if ok then
				table.insert(destinations, tile)
				--table.insert(interPoints, tile) -- DEBUG
			end
		end
		-- Add dest to table of destinations
		table.insert(destinations, dest)

		-- Plot a path along both points
		nav = Navigator(src, destinations, occupiedTiles)
		tiles = nav:plot()

		-- Make bricks at these coordinates
		for j,b in pairs(tiles) do
			table.insert(self.bricks, Brick(b))
		end
	end

	-- Do a floodfill on the inside of the room
	ff = FloodFiller(midPoint, self.bricks)
	ffResults = ff:flood()

	-- Save freeTiles and bricks
	self.freeTiles = ffResults.freeTiles
	tempBricks = ffResults.hotLava

	-- Remove any bricks that could not be touched from inside the room
	self.bricks = {}
	for i,b in pairs(tempBricks) do
		if b.touched == true then
			table.insert(self.bricks, Brick(b))
		--else
		--	print('removed an unreachable brick')
		end
	end

	print('room built')

	return {bricks = self.bricks, freeTiles = self.freeTiles,
	        midPoint = midPoint}
end

function RoomBuilder:order_exits()
	-- Index the exits in clockwise order
	temp = {}

	x = -1
	y = -1
	while true do
		-- Find the next exit on the current edge
		foundOne = false
		for i,e in pairs(self.exits) do
			-- Top
			if y == -1 and x < ROOM_W then
				if e.y == y and e.x > x then
					foundOne = true
					x = e.x
					table.insert(temp, e)
				end

			-- Right
			elseif x == ROOM_W and y < ROOM_H then
				if e.x == x and e.y > y then
					foundOne = true
					y = e.y
					table.insert(temp, e)
				end

			-- Bottom
			elseif y == ROOM_H and x > -1 then
				if e.y == y and e.x < x then
					foundOne = true
					x = e.x
					table.insert(temp, e)
				end

			-- Left
			elseif x == -1 then
				if e.x == x and e.y < y then
					foundOne = true
					y = e.y
					table.insert(temp, e)
				end
			end
		end 
		
		if foundOne == false then 
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
	end

	-- Replace old exit table with indexed version
	self.exits = temp
end
