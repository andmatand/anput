require('util.tile')

PathFinder = class('PathFinder')

function PathFinder:init(src, dest, hotLava, otherNodes, options)
    self.src = src
    self.dest = dest
    self.hotLava = hotLava -- Coordinates which are illegal to traverse
    self.otherNodes = otherNodes -- Other nodes (used to limit thickness)
    self.options = options -- {smooth = true} smoother path
    if self.options == nil then self.options = {} end
end

function PathFinder:legal_position(x, y)
    if x == self.dest.x and y == self.dest.y then
        return true
    end

    if self.options.lavaCache then
        local tile = self.options.lavaCache:get_tile({x = x, y = y})
        if #tile.contents > 0 then
            return false
        end
    elseif self.hotLava then
        for _, hl in pairs(self.hotLava) do
            if x == hl.x and y == hl.y then
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

    -- If a table of legal nodes was given
    if self.options.legalNodes then
        -- If this tile is not one of the legal nodes
        if not tile_in_table({x = x, y = y}, self.options.legalNodes) then
            return false
        end
    end

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
    local reachedDest = false

    -- Add source to self.openNodes
    table.insert(self.openNodes, {x = src.x, y = src.y, g = 0,
                                  h = manhattan_distance(src, dest)})

    local currentNode, parent
    local gPenalty
    while not reachedDest do
        -- Find best next openNode to use
        local lowestF = 9999
        local best = nil
        for i,n in ipairs(self.openNodes) do
            if n.g + n.h < lowestF then
                lowestF = n.g + n.h
                best = i
            end
        end
        
        if not best then
            print('A*: no path exists!')
            return {}
        end

        -- Remove the best node from openNodes and add it to closedNodes
        currentNode = self.openNodes[best]
        table.insert(self.closedNodes, table.remove(self.openNodes, best))
        parent = #self.closedNodes

        -- Add adjacent non-diagonal nodes to self.openNodes
        for d = 1, 4 do
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

            if self:legal_position(x, y) then
                alreadyFound = false
                for _, n in pairs(self.openNodes) do
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
                        if changed_direction({x = x, y = y}, currentNode,
                           self.closedNodes[currentNode.parent])
                        then
                            gPenalty = gPenalty + 4
                        end
                    end

                    -- Don't overlap other nodes unless absolutely necessary
                    if self.otherNodes ~= nil then
                        for i,n in pairs(self.otherNodes) do
                            if x == n.x and y == n.y then
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
