PathFinder = {}
PathFinder.__index = PathFinder

function PathFinder:new(srcX, srcY, destX, destY, hotLava, smooth)
	local o = {}
	setmetatable(o, self)

	o.srcX = srcX
	o.srcY = srcY
	o.destX = destX
	o.destY = destY
	o.hotLava = hotLava -- Coordinates which are illegal to traverse
	o.smooth = smooth -- If not nil, path will be smoother

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

local function distance(x1, y1, x2, y2)
	-- Manhattan distance
	return math.abs(x2 - x1) + math.abs(y2 - y1)
end

function PathFinder:AStar(src, dest)
	openNodes = {}
	closedNodes = {}
	reachedDest = false

	-- Add source to openNodes
	table.insert(openNodes, {x = src.x, y = src.y, g = 0,
	                         h = distance(src.x, src.y, dest.x, dest.y)})

	while reachedDest == false do
		-- Find best next openNode to use
		lowestF = 9999
		best = nil
		for i,n in ipairs(openNodes) do
			if n.g + n.h < lowestF then
				lowestF = n.g + n.h
				best = i
			end
		end
		
		if best == nil then
			print('A*: no path exists !!!!!!!!!!!!')
			love.timer.sleep(1000)
			-- No path exists
			break
		end

		-- Remove the best node from openNodes and add it to closedNodes
		currentNode = openNodes[best]
		table.insert(closedNodes, table.remove(openNodes, best))
		parent = #closedNodes

		--print('currentNode:', currentNode.x, currentNode.y)

		-- Add adjacent non-diagonal nodes to openNodes
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
				for i,n in pairs(openNodes) do
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
				for i,n in pairs(closedNodes) do
					if x == n.x and y == n.y then
						alreadyFound = true
						break
					end
				end

				-- If this node is not already in openNodes
				if not alreadyFound then
					gTurnPenalty = 0
					if self.smooth ~= nil and currentNode.parent ~= nil then
						if changed_direction({x = x, y = y}, currentNode,
											 closedNodes[currentNode.parent])
						then
							gTurnPenalty = 2
						end
					end
					table.insert(openNodes,
					             {x = x, y = y, parent = parent,
					              g = currentNode.g + 10 + gTurnPenalty,
					              h = distance(x, y, dest.x, dest.y)})
				end

				if x == dest.x and y == dest.y then
					table.insert(closedNodes, openNodes[#openNodes])
					reachedDest = true
					break
				end
			end
		end
	end

	-- Reconstruct path from destination back to source
	temp = {}
	n = closedNodes[#closedNodes]
	while true do
		table.insert(temp, n)

		-- Proceed to this node's parent
		n = closedNodes[n.parent]

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
