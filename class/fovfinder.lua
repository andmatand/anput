-- Returns distance between to points
local function distance(a, b)
	return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
end

local function round(num)
	--return math.floor(num + .5)
	return math.floor(num)
end


-- A Cone is a triangle of vision (used as an octant)
local Cone = class('Cone')

function Cone:init(args)
	self.octant = args.octant
	self.origin = args.origin -- Must be a table keyed with {x, y}
	self.slope1 = args.slope1
	self.slope2 = args.slope2
end

-- lineNum starts at 1
function Cone:get_line(lineNum)
	local tiles = {}, x, y, x1, x2, y1, y2

	-- Find the x, start y, and end y, based on line (column) number away from
	-- origin
	x = (lineNum - 1)
	y1 = (x * self.slope1)
	y2 = (x * self.slope2)

	-- Round to nearest tile
	--y1 = round(y1)
	--y2 = round(y2)

	-- Create a table of tiles in a line
	for y = y1, y2 do
		-- Translate the x, y coordinates to the correct octant
		tile = self:translate_octant({x = x, y = y})
		table.insert(tiles, tile)
	end

	return tiles
end

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
end

function FOVFinder:find()
	-- Octants
	-- \  |  /
	--  \1|2/
	--  8\|/3
	-- ---@---
	--  7/|\4
	--  /6|5\
	-- /  |  \

	local origin, slope1, slope2
	for octant = 1, 8 do
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
		local cone = Cone({origin = origin,
		                   octant = octant,
		                   slope1 = slope1,
		                   slope2 = slope2})

		for lineNum = 1, self.radius do
			local line = cone:get_line(lineNum)

			for _, tile in ipairs(line) do
				-- If this tile is within the radius
				if self:within_radius(tile) then
					-- DEBUG: show line tiles
					love.graphics.push()
					love.graphics.scale(TILE_W, TILE_H)
					if octant % 2 == 0 then
						love.graphics.setColor(0, 200, 0)
					else
						love.graphics.setColor(0, 0, 200)
					end
					love.graphics.setLine(1, 'rough')
					love.graphics.rectangle('line',
											tile.x, tile.y, 2, 2)
					love.graphics.pop()
				end
			end
		end
	end
end

function FOVFinder:scan(src, octant)
	local pos = {x = src.x, y = src.y}
	local line = 0

	while true do
		-- Move to next line
		if octant == 1 then
			line = line + 1
			pos.x = src.x - line
			pos.y = pos.y - 1
		end

		while true do
			-- Move to next position on line
			if octant == 1 then
				pos.x = pos.x + 1
			end

			-- If this tile contains an obstacle
			if tile_occupied(pos, self.obstacles) then
				self:scan()
			else
				table.insert(self.visibleTiles, pos)
			end
		end
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
