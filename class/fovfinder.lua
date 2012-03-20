require('util/tile')

--local DEBUG = true

-- Returns distance between to points
local function distance(a, b)
	return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
end

local function round(num)
	--return math.floor(num + .5)
	return math.floor(num)
end

local function slope(a, b)
	if (b.x - a.x) == 0 then
		return 0
	else
		return (b.y - a.y) / (b.x - a.x)
	end
end


-- A Cone is a triangle of vision (used as an octant)
local Cone = class('Cone')

function Cone:init(args)
	self.octant = args.octant
	self.origin = args.origin -- Must be a table keyed with {x, y}
	self.slope1 = args.slope1
	self.slope2 = args.slope2
end

-- Returns a column of tiles, rotated/translated to our octant.
-- colNums are:
--      #
--     ##
--    ###
--   ####
--   1234 etc.
function Cone:get_column(colNum)
	local tiles = {}
	local x, y, x1, x2, y1, y2

	-- Find the x, start y, and end y, based on (column number away from origin
	x = colNum - 1
	y1 = x * self.slope1
	y2 = x * self.slope2
	
	--print()
	--print('in get_column()')
	--print('slope1:', self.slope1)
	--print('x:', x)
	--print('y1:', y1)
	--print()

	-- Round to nearest tile
	y1 = round(y1)
	y2 = round(y2)

	-- Create a table of tiles in a column, top to bottom
	for y = y1, y2 do
		tile = {x = x, y = y}

		-- If this is the last tile in the column
		if y == y2 then
			-- Mark it as such
			tile.last = true
		end

		table.insert(tiles, tile)
	end

	return tiles
end

-- Returns the coordinates so that they are relative to the origin
function Cone:translate_origin(tile)
	return {x = self.origin.x + tile.x, y = self.origin.y + tile.y}
end

function Cone:translate_octant(tile)
	if self.octant == 1 then
        return self:translate_origin({x = tile.y, y = -tile.x})
	elseif self.octant == 2 then
        return self:translate_origin({x = -tile.y, y = -tile.x})
	elseif self.octant == 3 then
		return self:translate_origin(tile)
	elseif self.octant == 4 then
        return self:translate_origin({x = tile.x, y = -tile.y})
	elseif self.octant == 5 then
        return self:translate_origin({x = -tile.y, y = tile.x})
	elseif self.octant == 6 then
        return self:translate_origin({x = tile.y, y = tile.x})
	elseif self.octant == 7 then
        return self:translate_origin({x = -tile.x, y = -tile.y})
	elseif self.octant == 8 then
        return self:translate_origin({x = -tile.x, y = tile.y})
	end
end


-- A FOV finder finds a Field Of View (collection of tiles which are visibile
-- from a point within a room)
FOVFinder = class('Fov')

function FOVFinder:init(args)
	self.origin = args.origin
	self.radius = args.radius
	self.obstacles = args.obstacles
	self.room = args.room
end

function FOVFinder:find()
	self.visibleTiles = {}

	self:shadow_cast()

	-- DEBUG: show all visible tiles
	self:draw_visible_tiles(cone)

	return self.visibleTiles
end

function FOVFinder:shadow_cast()
	-- Octants
	-- \  |  /
	--  \1|2/
	--  8\|/3
	-- ---@---
	--  7/|\4
	--  /6|5\
	-- /  |  \

	-- Consider the origin visible
	table.insert(self.visibleTiles, self.origin)

	local origin
	local slope1
	local slope2
	for octant = 1, 8 do
	--for octant = 3, 3 do
		slope1 = -1
		slope2 = 0
		if octant == 1 then
			origin = {x = self.origin.x - 1, y = self.origin.y - 1}
		elseif octant == 2 then
			origin = {x = self.origin.x, y = self.origin.y - 1}
		elseif octant == 3 then
			origin = {x = self.origin.x + 1, y = self.origin.y - 1}
		elseif octant == 4 then
			origin = {x = self.origin.x + 1, y = self.origin.y}
		elseif octant == 5 then
			origin = {x = self.origin.x + 1, y = self.origin.y + 1}
		elseif octant == 6 then
			origin = {x = self.origin.x, y = self.origin.y + 1}
		elseif octant == 7 then
			origin = {x = self.origin.x - 1, y = self.origin.y + 1}
		elseif octant == 8 then
			origin = {x = self.origin.x - 1, y = self.origin.y}
		end

		local queue = {}

		-- If the origin for this octant is within the viewing radius
		if self.room:tile_in_room(origin, {includeBricks = true}) then
			-- Create the first cone
			local cone = Cone({origin = origin,
							   octant = octant,
							   slope1 = slope1,
							   slope2 = slope2})

			-- Place the first cone on the scan-queue
			table.insert(queue, {cone = cone, colNum = 1})

			-- DEBUG: draw all columns
			--for colNum = 1, self.radius do
			--	for _, tile in ipairs(cone:get_column(colNum)) do
			--		local transTile = cone:translate_octant(tile)

			--		love.graphics.setColor(255, 255, 255)
			--		love.graphics.setLine(1, 'rough')
			--		love.graphics.rectangle('line',
			--		                        transTile.x * TILE_W,
			--		                        transTile.y * TILE_H,
			--		                        TILE_W, TILE_H)
			--	end
			--end
		end


		if DEBUG then
			print()
			print('octant:', octant)
			print('origin:', origin.x, origin.y)
		end

		while #queue > 0 do
			local job = table.remove(queue)

			if DEBUG then
				print('colNum: ' .. job.colNum)
				print('  slope1: ' .. job.cone.slope1)
				print('  slope2: ' .. job.cone.slope2)
			end

			local sawAnyObstacles = false
			local sawAnyUnoccupied = false
			local previousTileWasOccupied = nil
			local newSlope1 = job.cone.slope1
			local newSlope2 = job.cone.slope2
			for i, tile in ipairs(job.cone:get_column(job.colNum)) do
				local transTile = job.cone:translate_octant(tile)
				local occupied = tile_occupied(transTile, self.obstacles)

				if DEBUG then
					print('  tile: ' .. tile.x .. ', ' .. tile.y)
					--print('  transTile:', transTile.x, transTile.y)
				end

				-- If this tile is within the viewing radius and in the room
				if (self:within_radius(transTile) and
					self.room:tile_in_room(transTile,
					                       {includeBricks = true})) then
					-- Consider this tile visible
					table.insert(self.visibleTiles, transTile)
				else
					occupied = true
				end

				if occupied then
					if DEBUG then
						print('    occupied')
					end

					sawAnyObstacles = true

					if previousTileWasOccupied == false then
						-- Find the slope to the top left of this tile
						newSlope2 = slope({x = 0, y = 0},
						                  {x = tile.x, y = tile.y - 1})
						if DEBUG then
							print('    set newSlope2 to ' .. newSlope2)
						end

						local newCone = Cone({origin = origin,
						                      octant = octant,
						                      slope1 = newSlope1,
						                      slope2 = newSlope2})

						-- Add another cone to the work queue with a slope2
						-- of right above this tile
						table.insert(queue, {cone = newCone,
						                     colNum = job.colNum + 1})

						if DEBUG then
							print('    queue add:')
							print('      newSlope1: ' .. newSlope1)
							print('      newSlope2:' .. newSlope2)
						end
					end

					previousTileWasOccupied = true
				else
					sawAnyUnoccupied = true

					if previousTileWasOccupied then
						-- Find the slope to the bottom right of the previous
						-- tile
						newSlope1 = slope({x = 0, y = 0},
						                  {x = tile.x + 1, y = tile.y - .1})
						
						-- Reset slope2
						--newSlope2 = slope2

						if DEBUG then
							print('    set newSlope1 to ' .. newSlope1)
						end
					end

					previousTileWasOccupied = false
				end

				-- If this is the last tile in the column
				if tile.last then
					if job.colNum == 1 or
					   (not occupied and sawAnyUnoccupied) then
						if DEBUG then
							print('    last:')
							print('      adding cone:')
							print('        slope1: ' .. newSlope1)
							print('        slope2: ' .. newSlope2)
						end

						-- Add the next column to the queue
						local newCone = Cone({origin = job.cone.origin,
						                      octant = job.cone.octant,
						                      slope1 = newSlope1,
						                      slope2 = newSlope2})

						table.insert(queue, {cone = newCone,
						                     colNum = job.colNum + 1})
					end
				end
			end
		end
	end
end

function FOVFinder:draw_visible_tiles()
	for _, tile in ipairs(self.visibleTiles) do
		love.graphics.setColor(0, 255, 0)
		love.graphics.setLine(1, 'rough')
		love.graphics.rectangle('line',
		                        tile.x * TILE_W, tile.y * TILE_H,
		                        TILE_W, TILE_H)
	end

	-- DEBUG: black out everything not visible
	--for y = 0, ROOM_H - 1 do
	--	for x = 0, ROOM_W - 1 do
	--		if not tile_occupied({x = x, y = y}, self.visibleTiles) then
	--			love.graphics.setColor(0, 0, 0)
	--			love.graphics.rectangle('fill',
	--									x * TILE_W, y * TILE_H,
	--									TILE_W, TILE_H)
	--		end
	--	end
	--end
end

function FOVFinder:within_radius(tile)
	-- If the distance from the center of the origin to the bottom left corner
	-- of the tile is less than the radius (zoom in 3x in calculation in order
	-- to pick in-between points)
	if distance({x = (self.origin.x * 3) + 1,
	             y = (self.origin.y * 3) + 1},
	            {x = (tile.x * 3),
	             y = (tile.y * 3) + 1}) < self.radius * 3 then
		return true
	else
		return false
	end
end
