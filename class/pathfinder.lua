PathFinder = {}
PathFinder.__index = PathFinder

function PathFinder:new(srcX, srcY, destX, destY, hotLava, otherNodes, options)
	local o = {}
	setmetatable(o, self)

	o.srcX = srcX
	o.srcY = srcY
	o.destX = destX
	o.destY = destY
	o.hotLava = hotLava -- Coordinates which are illegal to traverse
	o.otherNodes = otherNodes -- Other nodes (used to limit thickness)

	o.options = options -- {smooth = true} smoother path
	if o.options == nil then
		o.options = {}
	end

	return o
end

function PathFinder:legal_position(x, y)
	-- If this is an illegal tile
	if self.hotLava ~= nil then
		for i,b in pairs(self.hotLava) do
			if x == b.x and y == b.y then
				return false
			end
		end
	end

	-- If this tile is outside the bounds of the room
	if x < 0 or x > ROOM_W - 1 or y < 0 or y > ROOM_H - 1 then
		return false
	end

	-- If this tile is surrounded by

	return true
end

-- Plot a course which avoids the hotLava and room edges
-- Returns table of indexed coordinate pairs
function PathFinder:plot()
	self.nodes = self:AStar({x = self.srcX, y = self.srcY},
	             {x = self.destX, y = self.destY})

	return self.nodes
end

local function changed_direction(a, b, c)
	if (a.x == b.x and b.x == c.x) or (a.y == b.y and b.y == c.y) then
		return false
	end

	return true
end

function PathFinder:too_thick(x, y, currentNode)
	-- Add each successive parent-node to a map
	map = {}
	n = currentNode
	while true do
		table.insert(map, n)

		-- Proceed to this node's parent
		n = self.closedNodes[n.parent]

		-- If this node has no parent
		if n == nil then break end
	end
	-- Also add knowledge of other nodes
	table.insert(map, self.otherNodes)

	-- Check if there are 3 nodes bordering x, y so that a 2x2 square would be
	-- formed
	neighbors = {}
	for i = 1,8 do
		neighbors[i] = false
	end
	for i,n in pairs(map) do
		if n.x == x and n.y == y - 1 then
			neighbors[1] = true -- N
		elseif n.x == x + 1 and n.y == y - 1 then
			neighbors[2] = true -- NE
		elseif n.x == x + 1 and n.y == y then
			neighbors[3] = true -- E
		elseif n.x == x + 1 and n.y == y + 1 then
			neighbors[4] = true -- SE
		elseif n.x == x and n.y == y + 1 then
			neighbors[5] = true -- S
		elseif n.x == x - 1 and n.y == y + 1 then
			neighbors[6] = true -- SW
		elseif n.x == x - 1 and n.y == y then
			neighbors[7] = true -- W
		elseif n.x == x - 1 and n.y == y - 1 then
			neighbors[8] = true -- NW
		end

		-- Check for 3 in a row going clockwise
		numInARow = 0
		for j = 1,10 do
			-- Wrap around for last two
			if j > 8 then
				index = j - 8
			else
				index = j
			end

			if neighbors[index] == true then
				numInARow = numInARow + 1
			else
				numInARow = 0
			end

			if numInARow == 3 then
				print('\n\ntoo thick')
				return true
			end
		end
	end

	return false
end

local function distance(x1, y1, x2, y2)
	-- Manhattan distance
	return math.abs(x2 - x1) + math.abs(y2 - y1)
end

function PathFinder:AStar(src, dest)
	self.openNodes = {}
	self.closedNodes = {}
	reachedDest = false

	-- Add source to self.openNodes
	table.insert(self.openNodes, {x = src.x, y = src.y, g = 0,
	                         h = distance(src.x, src.y, dest.x, dest.y)})

	while reachedDest == false do
		-- Find best next openNode to use
		lowestF = 9999
		best = nil
		for i,n in ipairs(self.openNodes) do
			if n.g + n.h < lowestF then
				lowestF = n.g + n.h
				best = i
			end
		end
		
		if best == nil then
			print('A*: no path exists!')
			love.timer.sleep(1000)
			-- No path exists
			break
		end

		-- Remove the best node from openNodes and add it to closedNodes
		currentNode = self.openNodes[best]
		table.insert(self.closedNodes, table.remove(self.openNodes, best))
		parent = #self.closedNodes

		--print('currentNode:', currentNode.x, currentNode.y)

		-- Add adjacent non-diagonal nodes to self.openNodes
		for d = 1,4 do
			if d == 1 then
				-- North
				x = currentNode.x
				y = currentNode.y - 1
			elseif d == 2 then
				-- East
				x = currentNode.x + 1
				y = currentNode.y
			elseif d == 3 then
				-- South
				x = currentNode.x
				y = currentNode.y + 1
			elseif d == 4 then
				-- West
				x = currentNode.x - 1
				y = currentNode.y
			end

			if self:legal_position(x, y) then
				alreadyFound = false
				for i,n in pairs(self.openNodes) do
					if x == n.x and y == n.y then
						alreadyFound = true

						-- If we just found a faster route to this node
						if currentNode.g + 2 < n.g then
							n.parent = parent
							n.g = currentNode.g + 2
						end
						break
					end
				end
				for i,n in pairs(self.closedNodes) do
					if x == n.x and y == n.y then
						alreadyFound = true
						break
					end
				end

				-- If this node is not already in self.openNodes
				if not alreadyFound then
					--if self.options.smooth == true and
					--   self:too_thick(x, y, currentNode) then
					--	gPenalty = 4
					--else
					--	gPenalty = 0
					--end

					gPenalty = -1
					if self.options.smooth == true and
					   currentNode.parent ~= nil then
						if changed_direction(
							{x = x, y = y}, currentNode,
							self.closedNodes[currentNode.parent])
						then
							gPenalty = 4
						end
					end
					table.insert(self.openNodes,
					             {x = x, y = y, parent = parent,
					              g = currentNode.g + 10 + gPenalty,
					              h = distance(x, y, dest.x, dest.y)})
				end

				if x == dest.x and y == dest.y then
					table.insert(self.closedNodes,
					             self.openNodes[#self.openNodes])
					reachedDest = true
					break
				end
			end
		end
	end

	-- Reconstruct path from destination back to source
	temp = {}
	n = self.closedNodes[#self.closedNodes]
	while true do
		table.insert(temp, n)

		-- Proceed to this node's parent
		n = self.closedNodes[n.parent]

		-- If this node has no parent
		if n == nil then break end
	end

	-- Reverse the the path
	nodes = {}
	for i = #temp,1,-1 do
		table.insert(nodes, {x = temp[i].x, y = temp[i].y})
	end

	return nodes
end
