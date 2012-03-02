require('class/brick')
require('class/navigator')
require('class/floodfiller')

-- A RoomBuilder places bricks inside a room
RoomBuilder = class('RoomBuilder')

function RoomBuilder:init(exits)
	self.exits = exits -- A table of exit positions
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

		-- If the distance from src to dest is shorter than the distance from
		-- src to the room's midpoint
		local intermediatePoint
		if (manhattan_distance(src, dest) <
		    manhattan_distance(src, midPoint)) then
			-- Make a direct path to dest
			intermediatePoint = false
		else
			intermediatePoint = true
		end

		destinations = {}
		if intermediatePoint then
			-- Find the free tile which is closest to the midpoint
			local closestDist = 999
			local closestTile = nil
			for _, t in pairs(freeTiles) do
				dist = manhattan_distance(t, midPoint)
				if dist < closestDist then
					print('closestDist:', closestDist)
					closestDist = dist
					closestTile = t
				end
			end
			table.insert(destinations, closestTile)
		end

		-- Add dest to end of table of destinations
		table.insert(destinations, dest)

		-- Plot a path from src along all points in destinations
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
