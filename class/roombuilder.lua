require('class/brick')
require('class/navigator')
require('class/floodfiller')
require('util/tile')

local DEBUG = true

-- A RoomBuilder places bricks inside a room
RoomBuilder = class('RoomBuilder')

function RoomBuilder:init(room)
	self.room = room

	-- Make a working copy of the room's exits
	self.exits = copy_table(self.room.exits)

	self.bricks = {}
	self.occupiedTiles = {}

	if DEBUG then
		self.room.debugTiles = {}
	end
end

function RoomBuilder:add_occupied_tile(tile)
	-- Make sure this tile is not already in the table of
	-- occupied tiles
	for _, ot in pairs(self.occupiedTiles) do
		if tile.x == ot.x and tile.y == ot.y then
			return false
		end
	end
	table.insert(self.occupiedTiles, tile)

	return true
end

function RoomBuilder:build_next_piece()
	local timer
	if DEBUG then
		timer = love.timer.getTime()
	end

	if self:plot_midpaths() then
		if self:plot_walls() then
			if self:cleanup_untouchable_bricks() then
				self:finalize()

				-- Flag that all the pieces have been built
				return true
			end
		end
	end

	if DEBUG then
		local elapsed = love.timer.getTime() - timer
		if elapsed > 1 / fps then
			print('** took too long to build piece: ' .. elapsed)
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
	if self.cleanedUpUntouchableBricks then
		-- Flag that this step is already done
		return true
	end

	if not self.freeTiles then
		if DEBUG then
			print('doing floodfill to cleanup untouchable bricks')
		end

		self.freeTiles = {}

		-- Do a floodfill on the inside of the room, using the bricks as
		-- hotLava
		local ff = FloodFiller(self.midPoint, self.bricks)
		self.freeTiles = ff:flood()

		-- Add the midpoint to freeTiles, since it is not included by the
		-- floodfiller
		table.insert(self.freeTiles, self.midPoint)

		if DEBUG then
			for _, t in pairs(self.freeTiles) do
				table.insert(self.room.debugTiles, t)
			end
		end

		-- Flag that we did work
		return false
	end

	-- Remove any bricks that do not touch the inside of the room
	if DEBUG then
		print('removing bricks')
		print('before: ' .. #self.bricks .. ' bricks')
	end
	local temp = {}
	for _, b in pairs(self.bricks) do
		for _, t in pairs(self.freeTiles) do
			local ok = false

			if tiles_touching(b, t) then
				ok = true
			elseif math.random(0, 1) == 1 then
				if tiles_touching_diagonally(b, t) then
					ok = true
				end
			end

			if ok then
				table.insert(temp, Brick(b))
				break
			end
		end
	end
	self.bricks = temp

	if DEBUG then
		print('after: ' .. #self.bricks .. ' bricks')
	end

	self.cleanedUpUntouchableBricks = true

	-- TEST: check for duplicate bricks
	for _, a in pairs(self.bricks) do
		for _, b in pairs(self.bricks) do
			if a ~= b and tiles_overlap(a, b) then
				print('* duplicate brick')
			end
		end
	end

	-- Flag that we did work
	return false
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
			if DEBUG then
				print('plotting midpath from exit')
			end

			e.hasMidPath = true

			-- Give doorframeTiles as the only hotLava for this path
			local pf = PathFinder(e, self.midPoint, self.doorframeTiles)
			local tiles = pf:plot()

			-- Append these coordinates to list of illegal coordinates
			for _, b in pairs(tiles) do
				self:add_occupied_tile({x = b.x, y = b.y})
			end

			-- Flag that the midpaths are not yet complete
			return false
		end
	end

	if not self.accountedForRequiredObjects then
		self.accountedForRequiredObjects = true

		-- Iterate through the required objects for this room
		for _, obj in pairs(self.room.requiredObjects) do
			-- If this object will be an obstacle for the player
			if obj.isCorporeal then
				-- Choose a position for the center of the square that is not
				-- too close to any room edges
				local center = self.midPoint
				if center.x < 2 then
					center.x = center.x + 1
				elseif center.x > (ROOM_W - 1) - 2 then
					center.x = center.x - 1
				end
				if center.y < 2 then
					center.y = center.y + 1
				elseif center.y > (ROOM_H - 1) - 2 then
					center.y = center.y - 1
				end

				-- Mark off a square of tiles to make more room for the object
				for y = -1, 1 do
					for x = -1, 1 do
						self:add_occupied_tile({x = center.x + x,
						                        y = center.y + y})
					end
				end

				-- Only do this once
				break
			end
		end
	end

	-- Flag that the midpaths are complete
	return true
end

function RoomBuilder:plot_walls()
	if self.plottedWalls then
		return true
	end

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
			if DEBUG then
				print('doing floodfiller for wall')
			end

			e.hasFloodFill = true

			if DEBUG then
				timer = love.timer.getTime()
			end

			-- Find all vacant tiles accessible from the source doorframe
			local ff = FloodFiller(e.src, self.occupiedTiles)
			e.freeTiles = ff:flood()

			for k, v in pairs(self.occupiedTiles) do
				for k2, v2 in pairs(self.occupiedTiles) do
					if k ~= k2 and v.x == v2.x and v.y == v2.y then
						print('* redundant hotLava: ' .. v.x, v.y)
					end
				end
			end

			-- Remove dest from freeTiles
			for j, t in pairs(e.freeTiles) do
				if tiles_overlap(t, e.dest) then
					table.remove(e.freeTiles, j)
					break
				end
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

	self.plottedWalls = true
	print('finished plotting walls')

	-- Flag that we did work
	return false
end
