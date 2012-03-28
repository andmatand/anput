require('class/brick')
require('class/navigator')
require('class/floodfiller')

local DEBUG = false

-- A RoomBuilder places bricks inside a room
RoomBuilder = class('RoomBuilder')

function RoomBuilder:init(room)
	self.room = room

	-- Make a working copy of the room's exits
	self.exits = copy_table(self.room.exits)

	self.bricks = {}
	self.occupiedTiles = {}
	self.freeTiles = {}
end

function RoomBuilder:build_next_piece()
	if self:plot_midpaths() then
		if self:plot_walls() then
			if self:cleanup_untouchable_bricks() then
				self:finalize()

				-- Flag that all the pieces have been built
				return true
			end
		end
	end

	-- Flag that not all the pieces are done yet
	return false
end

function RoomBuilder:finalize()
	-- Give the room all the stuff we just made
	self.room.bricks = self.bricks
	self.room.freeTiles = self.freeTiles
	self.room.midPoint = self.midPoint
end

function RoomBuilder:cleanup_untouchable_bricks()
	-- Do a floodfill on the inside of the room, using the bricks as hotLava
	local ff = FloodFiller(self.midPoint, self.bricks)
	local ffResults = ff:flood()

	-- Save freeTiles
	self.freeTiles = ffResults.freeTiles

	-- Add the midpoint to freeTiles, since it is not included by the
	-- floodfiller
	table.insert(self.freeTiles, self.midPoint)

	-- Remove any bricks that could not be touched from inside the room
	self.bricks = {}
	for _, b in pairs(ffResults.hotLava) do
		if b.touched == true then
			table.insert(self.bricks, Brick(b))
		end
	end

	return true
end

function RoomBuilder:plot_midpaths()
	local timer
	if DEBUG then
		timer = love.timer.getTime()
	end

	if not self.midPoint then
		-- Pick a random point in the middle of the room
		self.midPoint = {x = math.random(1, ROOM_W - 2),
		                 y = math.random(1, ROOM_H - 2)}
	end

	if not self.doorframeTiles then
		-- Save positions of doorframe tiles at each exit
		self.doorframeTiles = {}
		for _, e in ipairs(self.exits) do
			local df = e:get_doorframes()
			table.insert(self.doorframeTiles, {x = df.x1, y = df.y1})
			table.insert(self.doorframeTiles, {x = df.x2, y = df.y2})
		end
	end

	-- Plot paths from all exits to the midpoint
	for _, e in pairs(self.exits) do
		if not e.hasMidPath then
			e.hasMidPath = true

			-- Give doorframeTiles as the only hotLava for this path
			local pf = PathFinder(e, self.midPoint, self.doorframeTiles)
			local tiles = pf:plot()

			-- Append these coordinates to list of illegal coordinates
			for _, b in pairs(tiles) do
				table.insert(self.occupiedTiles, {x = b.x, y = b.y})
				--if DEBUG then
				--	table.insert(midPaths, {x = b.x, y = b.y})
				--end
			end

			if DEBUG then
				print('generated midpath in ' .. love.timer.getTime() - timer)
			end

			-- Flag that the midpaths are not yet complete
			return false
		end
	end

	-- Flag that the midpaths are complete
	return true
end

function RoomBuilder:plot_walls()
	-- Make wall from right doorframe of each exit to left doorframe of next
	-- exit
	for i, e in ipairs(self.exits) do
		if not e.src then
			local df = e:get_doorframes()
			e.src = {x = df.x2, y = df.y2}
		end

		if not e.dest then
			local destdf

			-- If there is another exit to connect to
			if self.exits[i + 1] ~= nil then
				-- Set the next exit's left doorframe as the destination
				destdf = self.exits[i + 1]:get_doorframes()
			else
				-- Set the first exit's left doorframe as the destination
				destdf = self.exits[1]:get_doorframes()
			end

			e.dest = {x = destdf.x1, y = destdf.y1}
		end

		if not e.hasFloodFill then
			e.hasFloodFill = true

			if DEBUG then
				timer = love.timer.getTime()
			end

			-- Find all vacant tiles accessible from the source doorframe
			local ff = FloodFiller(e.src, self.occupiedTiles)
			e.freeTiles = ff:flood().freeTiles

			-- Remove dest from freeTiles
			for j, t in pairs(e.freeTiles) do
				if tiles_overlap(t, e.dest) then
					table.remove(e.freeTiles, j)
					break
				end
			end

			if DEBUG then
				print('did floodfill in ' .. love.timer.getTime() - timer)
			end

			-- The walls are not done yet
			return false
		end

		if not e.hasWall then
			e.hasWall = true

			-- If the distance from src to dest is shorter than the distance
			-- from src to the room's midpoint
			local intermediatePoint
			if (manhattan_distance(e.src, e.dest) <
				manhattan_distance(e.src, self.midPoint)) then
				-- Make a direct path to dest
				intermediatePoint = false
			else
				intermediatePoint = true
			end

			local destinations = {}
			if intermediatePoint then
				-- Find the free tile which is closest to the midpoint
				local closestDist = 999
				local closestTile = nil
				for _, t in pairs(e.freeTiles) do
					local dist = manhattan_distance(t, self.midPoint)
					if dist < closestDist then
						closestDist = dist
						closestTile = t
					end
				end
				table.insert(destinations, closestTile)
			end

			-- Add dest to end of table of destinations
			table.insert(destinations, e.dest)
			
			--if DEBUG then
			--	print('doing navigator:')
			--	print('  ' .. e.src.x .. ', ' .. e.src.y)
			--	for _, p in ipairs(destinations) do
			--		print('  ' .. p.x .. ', ' .. p.y)
			--	end
			--end

			-- Plot a path from src along all points in destinations
			local nav = Navigator(e.src, destinations, self.occupiedTiles)
			local tiles = nav:plot()

			-- Make bricks at these coordinates
			for _, b in pairs(tiles) do
				table.insert(self.bricks, Brick(b))
			end

			-- Flag that the walls are not done yet
			return false
		end
	end

	-- Flag that the walls are all done
	return true
end
