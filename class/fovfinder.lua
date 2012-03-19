require('util/tile')

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
		-- Translate the coordinates so that they are relative to the origin
		tile = self:translate_origin({x = x, y = y})

		-- If this is the last tile in the column
		if y == y2 then
			-- Mark it as such
			tile.last = true
		end

		table.insert(tiles, tile)
	end

	return tiles
end

function Cone:translate_origin(tile)
	return {x = self.origin.x + tile.x, y = self.origin.y + tile.y}
end

function Cone:translate_octant(tile)
	if self.octant == 1 then
        return {x = tile.y, y = -tile.x}
	elseif self.octant == 2 then
        return {x = -tile.y, y = -tile.x}
	elseif self.octant == 3 then
		return tile
	elseif self.octant == 4 then
        return {x = tile.x, y = -tile.y}
	elseif self.octant == 5 then
        return {x = -tile.y, y = tile.x}
	elseif self.octant == 6 then
        return {x = tile.y, y = tile.x}
	elseif self.octant == 7 then
        return {x = -tile.x, y = -tile.y}
	elseif self.octant == 8 then
        return {x = -tile.x, y = tile.y}
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

	local origin
	local slope1
	local slope2
	--for octant = 1, 8 do
	for octant = 3, 3 do
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
		end

		-- DEBUG
		print()
		print('octant:', octant)
		print('origin:', origin.x, origin.y)

		while #queue > 0 do
			local job = table.remove(queue)

			print('colNum:', job.colNum)
			print('slope1:', job.cone.slope1)
			print('slope2:', job.cone.slope2)

			local sawAnyObstacles = false
			local previousTileWasOccupied = nil
			local newSlope1 = job.cone.slope1
			local newSlope2 = job.cone.slope2
			for _, tile in ipairs(job.cone:get_column(job.colNum)) do
				-- DEBUG
				print('tile:', tile.x, tile.y)

				local transTile = job.cone:translate_octant(tile)
				local occupied = tile_occupied(transTile, self.obstacles)

				-- If this tile is within the viewing radius
				if self:within_radius(tile) then
					-- Consider this tile visible
					table.insert(self.visibleTiles, transTile)
				else
					occupied = true
				end

				if occupied then
					print('occupied')
					sawAnyObstacles = true

					if previousTileWasOccupied == false then
						-- Find the slope above this tile
						newSlope2 = slope(origin, {x = tile.x,
						                           y = tile.y - 1})

						local newCone = Cone({origin = origin,
						                      octant = octant,
						                      slope1 = newSlope1,
						                      slope2 = newSlope2})

						-- Add another cone to the work queue with a slope2
						-- of right above this tile
						table.insert(queue, {cone = newCone,
						                     colNum = job.colNum + 1})
						print('queue add:')
						print('  newSlope1:', newSlope1)
						print('  newSlope2:', newSlope2)
					end

					previousTileWasOccupied = true
				else
					if previousTileWasOccupied then
						-- Find the slope to this tile
						newSlope1 = slope(origin, {x = tile.x,
						                           y = tile.y})
						
						-- Reset slope2
						newSlope2 = slope2

						-- DEBUG
						print('set newSlope1 to ' .. newSlope1)
					end

					previousTileWasOccupied = false
				end

				-- If this is the last tile in the column
				if tile.last and not occupied then
					print('last:')
					print('  adding cone with slope1 of ' .. newSlope1)
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

function FOVFinder:draw_visible_tiles()
	for _, tile in ipairs(self.visibleTiles) do
		love.graphics.setColor(0, 255, 0)
		love.graphics.setLine(1, 'rough')
		love.graphics.rectangle('line',
		                        tile.x * TILE_W, tile.y * TILE_H,
		                        TILE_W, TILE_H)
	end
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
