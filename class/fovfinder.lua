-- Returns distance between to points
local function distance(a, b)
	return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
end

-- Convert degrees to radians
local function to_rad(deg)
	return deg / 180 * math.pi
end 
 
-- Rotate point around an origin
local function rotate_point(point, origin, degrees)
	local x = origin.x + (math.cos(to_rad(degrees)) * (point.x - origin.x) -
	                      math.sin(to_rad(degrees)) * (point.y - origin.y))
	local y = origin.y + (math.sin(to_rad(degrees)) * (point.x - origin.x) +
	                      math.cos(to_rad(degrees)) * (point.y - origin.y))
	return {x = x, y = y}
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
	x = self.origin.x + (lineNum - 1)
	y1 = ((x - self.origin.x) * self.slope1) + self.origin.y
	y2 = ((x - self.origin.x) * self.slope2) + self.origin.y

	-- Determine rotation amount based on distance from octant 3, which has no
	-- rotation
	if self.octant == 1 then
		rotation = -90
	elseif self.octant == 2 then
		rotation = -45
	elseif self.octant == 3 then
		rotation = 0
	elseif self.octant == 4 then
		rotation = 45
	elseif self.octant == 5 then
		rotation = 90
	elseif self.octant == 6 then
		rotation = 135
	elseif self.octant == 7 then
		rotation = 180
	elseif self.octant == 8 then
		rotation = 225
	end

	-- Create a table of tiles in a line
	for y = y1, y2 do
		-- Rotate the x, y coordinates
		tile = rotate_point({x = x, y = y}, self.origin, rotation)

		-- Round to nearest tile
		tile.x = round(tile.x)
		tile.y = round(tile.y)

		table.insert(tiles, tile)
	end

	return tiles
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
	-- Zoom the points x2 and use the corner of tile that is closest to the
	-- origin
	t = {}
	if tile.x >= self.origin.x then
		t.x = tile.x * 2
	else
		t.x = (tile.x * 2) + 1
	end
	if tile.y >= self.origin.y then
		t.y = tile.y * 2
	else
		t.y = (tile.y * 2) + 1
	end

	if distance({x = t.x, y = t.y},
	            {x = self.origin.x * 2,
	             y = self.origin.y * 2}) < self.radius * 2 then
		return true
	else
		return false
	end

	--if distance(tile, self.origin) < self.radius then
	--	return true
	--else
	--	return false
	--end
end
