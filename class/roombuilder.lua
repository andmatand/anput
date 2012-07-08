require('class/brick')
require('class/navigator')
require('class/floodfiller')
require('util/tables')
require('util/tile')

--local DEBUG = true

local function cheap_line(src, dest)
    local nodes = {}
    local pos = {x = src.x, y = src.y}

    if DEBUG then
        --print('finding cheap line')
        --print('  src: ' .. src.x .. ', ' .. src.y)
        --print('  dest: ' .. dest.x .. ', ' .. dest.y)
        --print()
    end

    -- Add the src position
    table.insert(nodes, {x = pos.x, y = pos.y})

    repeat
        local moveX = false
        local moveY = false

        if pos.x ~= dest.x and (math.random(0, 1) == 0 or
                                pos.y == dest.y) then
            moveX = true
        else
            moveY = true
        end

        -- If we are on the room border, move in by one tile
        if pos.x == 0 or pos.x == ROOM_W - 1 then
            moveX = true
            moveY = false
        elseif pos.y == 0 or pos.y == ROOM_H - 1 then
            moveX = false
            moveY = true
        end

        if moveX then
            if pos.x < dest.x then
                pos.x = pos.x + 1
            elseif pos.x > dest.x then
                pos.x = pos.x - 1
            end
        elseif moveY then
            if pos.y < dest.y then
                pos.y = pos.y + 1
            elseif pos.y > dest.y then
                pos.y = pos.y - 1
            end
        end

        --print('  pos:' .. pos.x .. ', ' .. pos.y)

        -- Add the current position
        table.insert(nodes, {x = pos.x, y = pos.y})
    until tiles_overlap(pos, dest)

    return nodes
end

-- A RoomBuilder places bricks inside a room
RoomBuilder = class('RoomBuilder')

function RoomBuilder:init(room)
    self.room = room

    -- Make a working copy of the room's exits
    self.exits = copy_table(self.room.exits)

    self.bricks = {}
    self.occupiedTiles = {}
end

function RoomBuilder:add_occupied_tile(tile)
    -- Make sure this tile is not already in the table of
    -- occupied tiles
    for _, ot in pairs(self.occupiedTiles) do
        if tile.x == ot.x and tile.y == ot.y then
            return false
        end
    end
    table.insert(self.occupiedTiles, tile)

    return true
end

function RoomBuilder:build()
    if self.room.isBuilt or self.room.isBeingBuilt then
        return false
    end

    -- Initialize PRNG with the room's speicfied random seed
    math.randomseed(self.room.randomSeed)

    local timer
    if DEBUG then
        timer = love.timer.getTime()
    end

    -- Mark the room as being built
    self.room.isBeingBuilt = true

    self:plot_midpaths()
    self:plot_walls()
    self:cleanup_untouchable_bricks()
    self:finalize()

    if DEBUG and timer then
        local elapsed = love.timer.getTime() - timer
        print('built room ' .. self.room.index .. ' in ' .. elapsed)
    end

    return true
end

function RoomBuilder:finalize()
    -- Give the room all the stuff we just made
    self.room.bricks = self.bricks
    self.room.freeTiles = self.freeTiles
    self.room.midPoint = self.midPoint
    self.room.midPaths = self.occupiedTiles

    -- Mark the room as built
    self.room.isBuilt = true
    self.room.isBeingBuilt = false
end

function RoomBuilder:cleanup_untouchable_bricks()
    -- Do a floodfill on the inside of the room, using the bricks as hotLava
    local ff = FloodFiller(self.midPoint, self.bricks)
    self.freeTiles = ff:flood()

    -- Add the midpoint to freeTiles, since it is not included by the
    -- floodfiller
    table.insert(self.freeTiles, self.midPoint)

    -- Remove any bricks that do not touch the inside of the room
    local newBricks = {}
    for i, b in pairs(self.bricks) do
        for _, t in pairs(self.freeTiles) do
            local ok = false

            if tiles_touching(b, t) then
                ok = true
            elseif math.random(0, 1) == 1 then
                if tiles_touching_diagonally(b, t) then
                    ok = true
                end
            end

            -- Make sure this brick isn't in the same position as another
            -- brick that was already added
            if ok then
                for _, b2 in pairs(newBricks) do
                    if tiles_overlap(b, b2) then
                        ok = false
                        break
                    end
                end
            end

            if ok then
                table.insert(newBricks, Brick(b))
                break
            end
        end
    end
    self.bricks = newBricks
end

function RoomBuilder:plot_midpaths()
    -- Pick a random point in the middle of the room
    self.midPoint = {x = math.random(1, ROOM_W - 2),
                     y = math.random(1, ROOM_H - 2)}

    -- Plot paths from all exits to the midpoint
    for _, e in pairs(self.exits) do
        if DEBUG then
            print('plotting midpath from exit')
        end

        -- Add the exit position to the list of illegal coordinates
        self:add_occupied_tile({x = e.x, y = e.y})

        -- Get the position into the room by one tile
        local src = {x = e.x, y = e.y}
        if src.y == -1 then
            src.y = src.y + 1
        elseif src.x == ROOM_W then
            src.x = src.x - 1
        elseif src.y == ROOM_H then
            src.y = src.y - 1
        elseif src.x == -1 then
            src.x = src.x + 1
        end

        local tiles = cheap_line(src, self.midPoint)

        -- Append these coordinates to list of illegal coordinates
        for _, t in pairs(tiles) do
            self:add_occupied_tile({x = t.x, y = t.y})
        end

        --if DEBUG then
        --    table.insert(self.room.debugTiles, {x = e.x, y = e.y})
        --    for _, t in pairs(tiles) do
        --        table.insert(self.room.debugTiles, t)
        --    end
        --end
    end

    -- Iterate through the required objects for this room
    if self.room.needsSpaceForNPC then
        -- Choose a position for the center of the square that is not
        -- too close to any room edges
        local center = self.midPoint
        if center.x < 2 then
            center.x = center.x + 1
        elseif center.x > (ROOM_W - 1) - 2 then
            center.x = center.x - 1
        end
        if center.y < 2 then
            center.y = center.y + 1
        elseif center.y > (ROOM_H - 1) - 2 then
            center.y = center.y - 1
        end

        -- Mark off a square of tiles to make more room for the object
        for y = -1, 1 do
            for x = -1, 1 do
                self:add_occupied_tile({x = center.x + x,
                                        y = center.y + y})
            end
        end
    end
end

function RoomBuilder:plot_walls()
    -- Make wall from right doorframe of each exit to left doorframe of next
    -- exit
    for i, e in ipairs(self.exits) do
        local df = e:get_doorframes()
        local src = {x = df.x2, y = df.y2}

        local destdf
        -- If there is another exit to connect to
        if self.exits[i + 1] ~= nil then
            -- Set the next exit's left doorframe as the destination
            destdf = self.exits[i + 1]:get_doorframes()
        else
            -- Set the first exit's left doorframe as the destination
            destdf = self.exits[1]:get_doorframes()
        end
        local dest = {x = destdf.x1, y = destdf.y1}


        -- Find all vacant tiles accessible from the source doorframe
        local ff = FloodFiller(src, self.occupiedTiles)
        e.freeTiles = ff:flood()

        for k, v in pairs(self.occupiedTiles) do
            for k2, v2 in pairs(self.occupiedTiles) do
                if k ~= k2 and v.x == v2.x and v.y == v2.y then
                    print('* redundant hotLava: ' .. v.x, v.y)
                end
            end
        end

        -- Remove dest from freeTiles
        for j, t in pairs(e.freeTiles) do
            if tiles_overlap(t, dest) then
                table.remove(e.freeTiles, j)
                break
            end
        end


        -- If the distance from src to dest is shorter than the distance
        -- from src to the room's midpoint
        local intermediatePoint
        --if (manhattan_distance(src, dest) <
        --  manhattan_distance(src, self.midPoint)) then
        --  -- Make a direct path to dest
        --  intermediatePoint = false
        --else
        --  intermediatePoint = true
        --end
        intermediatePoint = true

        local destinations = {}
        if intermediatePoint then
            -- Find a free tile which is close to an occupied tile
            for _, t in pairs(e.freeTiles) do
                if manhattan_distance(t, self.midPoint) <= 5 then
                    table.insert(destinations, t)
                    break
                end
            end
        end

        -- Add dest to end of table of destinations
        table.insert(destinations, dest)
        
        --if DEBUG then
        --  print('doing navigator:')
        --  print('  ' .. src.x .. ', ' .. src.y)
        --  for _, p in ipairs(destinations) do
        --      print('  ' .. p.x .. ', ' .. p.y)
        --  end
        --end

        -- Plot a path from src along all points in destinations
        nav = Navigator(src, destinations, self.occupiedTiles)
        tiles = nav:plot()

        -- Make bricks at these coordinates
        for _, b in pairs(tiles) do
            table.insert(self.bricks, Brick(b))
        end
    end
end
