require 'class/pathfinder.lua'

Map = {}
Map.__index = Map

function Map:new()
	local o = {}
	setmetatable(o, self)

	o.source = source

	return o
end

function Map:generate()
	self.path = self:generate_path()
	self:add_branches(self.path)

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

function tile_occupied(tile, otherTilesTable)
	for i,t in pairs(otherTilesTable) do
		for j,n in pairs(t) do
			if tile.x == n.x and tile.y == n.y then
				return true
			end
		end
	end
	return false
end

function find_empty_neighbors(node, otherNodesTables)
	-- Combine all tables in otherNodesTables
	allOtherNodes = {}
	for i,t in pairs(otherNodesTables) do
		for k,v in pairs(t) do
			table.insert(allOtherNodes, v)
		end
	end

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
	self.branches = {}
	for i,p in pairs(path) do
		-- Don't branch off from the final room
		if i == #path then break end

		--print('\npath node ' .. i .. ':', p.x, p.y)

		neighbors = find_empty_neighbors(p, {path, self.branches})

		for j,n in pairs(neighbors) do
			if math.random(0, 2) == 0 then
				-- Form a branch starting from this neighbor
				table.insert(self.branches, n)

				maxLength = math.random(1, 6)
				branchLength = 1
				tile = n
				while branchLength < maxLength do
					possibleMoves = find_empty_neighbors(tile,
														 {path, self.branches})

					if #possibleMoves > 0 then
						-- Move randomly to one of the open neighbors
						tile = possibleMoves[math.random(1, #possibleMoves)]
						branchLength = branchLength + 1
						table.insert(self.branches, tile)
					else
						break
					end
				end
			end
		end
	end
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
	pf = PathFinder:new(src, dest, self.obstacles, nil, {bounds = false})
	path = pf:plot()

	return path
end

function Map:generate_rooms()
	for i,n in pairs(self.path) do
	end
end
