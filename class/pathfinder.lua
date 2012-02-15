require('tile')

PathFinder = class('PathFinder')

function PathFinder:init(src, dest, hotLava, otherNodes, options)
	self.src = src
	self.dest = dest
	self.hotLava = hotLava -- Coordinates which are illegal to traverse
	self.otherNodes = otherNodes -- Other nodes (used to limit thickness)
	self.options = options -- {smooth = true} smoother path
	if self.options == nil then self.options = {} end
end

function find_neighbors(node, otherNodes, options)
	if options == nil then options = {} end

	-- Initialize all 8 neighbors' positions
	neighbors = {}
	for d = 1,8 do
		n = {occupied = false}
		if d == 1 then -- N
			n.x = node.x
			n.y = node.y - 1
		elseif d == 2 then -- NE
			n.x = node.x + 1
			n.y = node.y - 1
		elseif d == 3 then -- E
			n.x = node.x + 1
			n.y = node.y
		elseif d == 4 then -- SE
			n.x = node.x + 1
			n.y = node.y + 1
		elseif d == 5 then -- S
			n.x = node.x
			n.y = node.y + 1
		elseif d == 6 then -- SW
			n.x = node.x - 1
			n.y = node.y + 1
		elseif d == 7 then -- W
			n.x = node.x - 1
			n.y = node.y
		elseif d == 8 then -- NW
			n.x = node.x - 1
			n.y = node.y - 1
		end

		neighbors[d] = n
	end

	-- Check if any of the otherNodes are in the neighbor positions
	for i,o in pairs(otherNodes) do
		for j,n in pairs(neighbors) do
			if o.x == n.x and o.y == n.y then
				n.room = o.room
				n.occupied = true
			end
		end
	end

	if options.countBorders == true then
		-- Check if any of the neighbor positions touch the room border
		for i,n in pairs(neighbors) do
			if n.y == 0 or
			   n.x == ROOM_W - 1 or
			   n.y == ROOM_H - 1 or
			   n.x == 0 then
				n.occupied = true
			end
		end
	end

	if options.diagonals == false then
		-- Remove diagonal neighbors
		temp = {}
		for i,n in ipairs(neighbors) do
			if i == 1 or i == 3 or i == 5 or i == 7 then
				table.insert(temp, n)
			end
		end
		neighbors = temp
	end

	return neighbors
end

function PathFinder:legal_position(x, y)
	if x == self.dest.x and y == self.dest.y then
		return true
	end

	-- If this is an illegal tile
	if self.hotLava ~= nil then
		for j,b in pairs(self.hotLava) do
			if x == b.x and y == b.y then
				return false
			end
		end
	end

	-- If this tile is outside the bounds of the room
	if self.options.bounds ~= false then
		if tile_offscreen({x = x, y = y}) then
			return false
		end
	end

	-- If this tile is surrounded by

	return true
end

-- Plot a course which avoids the hotLava and room edges
-- Returns table of indexed coordinate pairs
function PathFinder:plot()
	self.nodes = self:AStar(self.src, self.dest)

	return self.nodes
end

local function changed_direction(a, b, c)
	if (a.x == b.x and b.x == c.x) or (a.y == b.y and b.y == c.y) then
		return false
	end

	return true
end

function PathFinder:AStar(src, dest)
	if src.x == dest.x and src.y == dest.y then
		return {src}
	end

	self.openNodes = {}
	self.closedNodes = {}
	reachedDest = false

	-- Add source to self.openNodes
	table.insert(self.openNodes, {x = src.x, y = src.y, g = 0,
	                         h = manhattan_distance(src, dest)})

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
			--love.timer.sleep(1000)
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
			gPenalty = 0
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

			--if d == 5 then
			--	-- NE
			--	x = currentNode.x + 1
			--	y = currentNode.y - 1
			--	gPenalty = 4
			--elseif d == 6 then
			--	-- SE
			--	x = currentNode.x + 1
			--	y = currentNode.y + 1
			--	gPenalty = 4
			--elseif d == 7 then
			--	-- SW
			--	x = currentNode.x - 1
			--	y = currentNode.y + 1
			--	gPenalty = 4
			--elseif d == 8 then
			--	-- NW
			--	x = currentNode.x - 1
			--	y = currentNode.y - 1
			--	gPenalty = 4
			--end

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
					if self.options.smooth == true and
					   currentNode.parent ~= nil then
						if changed_direction(
							{x = x, y = y}, currentNode,
							self.closedNodes[currentNode.parent])
						then
							gPenalty = gPenalty + 4
						end
					end

					-- Don't overlap other paths unless absolutely necessary
					if self.otherNodes ~= nil then
						for i,n in pairs(self.otherNodes) do
							if x == (n.x) and y == (n.y) then
								gPenalty = 20
							elseif math.abs(x - n.x) <= 1 and
							       math.abs(y - n.y) <= 1 then
								gPenalty = 10
							end
						end
					end

					table.insert(self.openNodes,
					             {x = x, y = y, parent = parent,
					              g = currentNode.g + 10 + gPenalty,
					              h = manhattan_distance({x = x,  y = y},
					                                     dest)})
				end
			end
			if x == dest.x and y == dest.y then
				table.insert(self.closedNodes,
							 self.openNodes[#self.openNodes])
				reachedDest = true
				break
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
