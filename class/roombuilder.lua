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

local function order_axis(key, src, dest, nodes)
	print('starting order_axis')
	for i,n in pairs(nodes) do
		print(n[key])
	end
	ordered = {}

	-- Choose direction for ordering based on which way we are going
	if src < dest then
		best = 999
		-- Low to high
		print('low to high')
		compare =
			function(a, b)
				if a <= b then
					return true
				end
				return false
			end
	elseif src > dest then
		best = -1
		-- High to low
		print('high to low')
		compare =
			function(a, b)
				if a >= b then
					return true
				end
				return false
			end
	end

	if compare ~= nil then
		-- Order based on position on axis
		while true do
			-- Find best next position on the axis
			for i,n in pairs(nodes) do
				if compare(n[key], best) then
					best = n[key]
				end
			end

			--print('\nnodes:')
			--for i,n in pairs(nodes) do
			--	print(n[key])
			--end
			--print('best:', best)
			--if #nodes == 2 then love.timer.sleep(1000) end

			-- Find the first node that has the best next position
			for i,n in ipairs(nodes) do
				if n[key] == best then
					-- Add this point to the ordered table
					table.insert(ordered, table.remove(nodes, i))

					-- Reset best to an arbitrary existing node's value
					if #nodes ~= 0 then
						best = nodes[#nodes][key]
					end
					
					break
				end
			end

			if #nodes == 0 then
				break
			end
		end
	end
	return ordered
end

local function order_nodes(srcX, srcY, destX, destY, nodes)
	print('starting order_nodes()')

	orderedX = order_axis('x', srcX, destX, nodes)
	orderedY = order_axis('y', srcY, destY, orderedX)

	print('done with order_nodes()')
	return orderedY
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
	--table.insert(self.bricks, Brick:new(midX, midY))
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

		-- Find all vacant tiles accessible from the source doorway
		print(srcX, srcY)
		ff = FloodFiller:new(srcX, srcY, occupiedTiles)
		freeTiles = ff:flood()
		--numFreeTiles = len(freeTiles)

		-- Pick 1-3 random intermediate points in the avaiable space
		numPoints = math.random(1, 3)
		points = {}
		for j = 1, (numPoints * 2) do
			tile = freeTiles[math.random(1, #freeTiles)] 

			ok = true
			-- Don't pick points that overlap with src or dest
			if not ((tile.x == srcX and tile.y == srcY) or
			        (tile.x == destX and tile.y == destY)) then
			end

			-- Look at the other points
			for k,p2 in pairs(points) do
				--If these two nodes are too close together on one axis
				if math.abs(tile.x - p2.x) < 2 or
				   math.abs(tile.y - p2.y) < 2 then
					ok = false
				end
			end

			if ok then
				table.insert(points, {x = tile.x, y = tile.y})
			end

			if #points == numPoints then break end
		end
		
		-- Index the points in the best order
		points = order_nodes(srcX, srcY, destX, destY, points)
		print('ordered points:', points)

		-- Add all points to a table of destinations
		destinations = {}
		for j,p in ipairs(points) do
			destinations[j] = {x = p.x, y = p.y}
		end
		destinations[#points + 1] = {x = destX, y = destY}

		for j,d in ipairs(destinations) do
			print('destination ' .. j .. ': ' .. d.x .. ',' .. d.y)
		end

		-- Plot a path along all points
		nav = Navigator:new(dw.x2, dw.y2, destinations, occupiedTiles)
		tiles = nav:plot()

		--pf = PathFinder:new(dw.x2, dw.y2, destX, destY, occupiedTiles, true)
		--tiles = pf:plot()

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
