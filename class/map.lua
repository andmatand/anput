require('exit')
require('mapdisplay')
require('pathfinder')
require('room')
require('tables')

-- A Map generates a random contiguous layout of rooms and their exits
Map = class('Map')

function Map:generate()
	self.path = self:generate_path()
	self.branches = self:add_branches(self.path)
	self.display = nil

	return self:generate_rooms()
end

function move_random(node)
	if math.random(0, 1) == 0 then
		-- Move x
		if math.random(0, 1) == 0 then
			node.x = node.x - 1
		else
			node.x = node.x + 1
		end
	else
		-- Move y
		if math.random(0, 1) == 0 then
			node.y = node.y - 1
		else
			node.y = node.y + 1
		end
	end
end

function find_empty_neighbors(node, otherNodesTables)
	-- Combine all tables in otherNodesTables
	allOtherNodes = concat_tables(otherNodesTables)

	neighbors = find_neighbors(node, allOtherNodes, {diagonals = false})

	-- Keep only empty neighbors
	temp = {}
	for j,n in pairs(neighbors) do
		ok = true

		if n.occupied == true then
			ok = false
		end

		if ok then
			table.insert(temp, n)
		end
	end
	neighbors = temp

	--print('empty neighbors:')
	--for j,n in pairs(neighbors) do
	--	print(n.x, n.y)
	--end

	return neighbors
end

function Map:add_branches(path)
	branches = {}
	for i,p in pairs(path) do
		-- Don't branch off from the final room
		if i == #path then break end

		--print('\npath node ' .. i .. ':', p.x, p.y)

		neighbors = find_empty_neighbors(p, {path, branches})

		for j,n in pairs(neighbors) do
			if math.random(0, 2) == 0 then
				-- Form a branch starting from this neighbor
				table.insert(branches, n)

				maxLength = math.random(1, 6)
				branchLength = 1
				tile = n
				while branchLength < maxLength do
					possibleMoves = find_empty_neighbors(tile,
														 {path, branches})

					if #possibleMoves > 0 then
						-- Move randomly to one of the open neighbors
						tile = possibleMoves[math.random(1, #possibleMoves)]
						branchLength = branchLength + 1
						table.insert(branches, tile)
					else
						break
					end
				end
			end
		end
	end

	return branches
end

function Map:draw(currentRoom)
	self.display:draw(currentRoom)
end

function Map:generate_path()
	src = {x = 0, y = 0}

	-- Pick random location for the final room
	breadth = 15
	distance = {}
	distance.x = math.random(-breadth, breadth)
	distance.y = breadth - math.abs(distance.x)
	if math.random(0, 1) == 0 then
		distance.y = -distance.y
	end
	dest = {x = src.x + distance.x, y = src.y + distance.y}

	-- Find the rectangle of space between the two points
	rect = {}
	if src.x <= dest.x then
		rect.x1 = src.x
		rect.x2 = dest.x
	else
		rect.x1 = dest.x
		rect.x2 = src.x
	end
	if src.y <= dest.y then
		rect.y1 = src.y
		rect.y2 = dest.y
	else
		rect.y1 = dest.y
		rect.y2 = src.y
	end

	-- Place some obstacles in between the rooms
	self.obstacles = {}
	for i = 1,(breadth * 3) do
		x = math.random(rect.x1, rect.x2)
		y = math.random(rect.y1, rect.y2)

		ok = true
		if (x == src.x and y == src.y) or
		   (x == dest.x and y == dest.y) then
		   ok = false
		end

		if ok then
			table.insert(self.obstacles, {x = x, y = y})
		end
	end

	-- Plot path from src to dest through obstacles
	pf = PathFinder(src, dest, self.obstacles, nil, {bounds = false})
	path = pf:plot()
	path[#path].finalRoom = true

	return path
end

function Map:generate_rooms()
	-- Combine the path and branches into one table
	self.nodes = concat_tables({self.path, self.branches})

	-- Make a new room for each node
	rooms = {}
	for i,node in ipairs(self.nodes) do
		--print('\nnode ' .. i)
		neighbors = find_neighbors(node, self.nodes, {diagonals = false})

		-- Add exits to correct walls of room
		exits = {}
		for j,n in ipairs(neighbors) do
			if n.occupied then
				--if n.room ~= nil then
				--	print('neighbor ' .. j .. ' is a room with ' ..
				--	      #n.room.exits .. ' exits')
				--	for k,e in pairs(n.room.exits) do
				--		print('  exit ' .. k .. ': ', e.x, e.y, e.roomIndex)
				--	end
				--else
				--	print('neighbor ' .. j .. ' is not a room yet')
				--end
				linkedExit = nil

				x = math.random(2, ROOM_W - 2)
				y = math.random(2, ROOM_H - 2)
				if j == 1 then
					y = -1 -- North

					-- If this neighbor has already been converted into a room
					-- with exits, use the position of its corresponding exit
					if n.room ~= nil then
						linkedExit = n.room:get_exit({y = ROOM_H})
						x = linkedExit.x
					end
				elseif j == 2 then
					x = ROOM_W -- East
					if n.room ~= nil then
						linkedExit = n.room:get_exit({x = -1})
						y = linkedExit.y
					end
				elseif j == 3 then
					y = ROOM_H -- South
					if n.room ~= nil then
						linkedExit = n.room:get_exit({y = -1})
						x = linkedExit.x
					end
				elseif j == 4 then
					x = -1 -- West
					if n.room ~= nil then
						linkedExit = n.room:get_exit({x = ROOM_W})
						y = linkedExit.y
					end
				end

				newExit = Exit({x = x, y = y})
				if linkedExit ~= nil then
					linkedExit.roomIndex = #rooms + 1
					newExit.roomIndex = n.room.index
				end
				--print('new exit:', newExit.x, newExit.y, newExit.roomIndex)

				table.insert(exits, newExit)
			end
		end

		-- Add the new room and attach it to this node
		r = Room({exits = exits, index = #rooms + 1})
		r.distanceFromEnd = manhattan_distance(node, self.path[#self.path])
		table.insert(rooms, r)
		node.room = r
	end

	-- Assign difficulty to each room based on distance from final room
	-- compared to farthest room
	--for _, r in pairs(rooms) do
	--end

	-- Create a display of this map
	self.display = MapDisplay(self.nodes)

	return rooms
end
