require('class.brick')
require('class.cheappathfinder')
require('class.floodfiller')
require('class.lake')
require('class.navigator')
require('util.tables')
require('util.tile')

--local DEBUG = true

-- A RoomBuilder places bricks inside a room
RoomBuilder = class('RoomBuilder')

function RoomBuilder:init(room)
    self.room = room

    -- Make a working copy of the room's exits
    self.exits = copy_table(self.room.exits)

    self.bricks = {}
    self.occupiedTiles = {}
    self.zoneTiles = {}
    self.midPaths = {}
    self.lakes = {}

    self.lakeSources = {}
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

function RoomBuilder:add_required_zone()
    if not self.room.requiredZone then
        return
    end

    local rectangle = {}

    if self.room.requiredZone.name == 'npc' then
        rectangle.w = 3
        rectangle.h = 3
        rectangle.center = self.midPoint
    elseif self.room.requiredZone.name == 'lake' then
        -- Determine which exit is the entrance and which is the blocked exit
        for _, exit in pairs(self.room.exits) do
            if exit:get_direction() == self.room.requiredZone.dir then
                self.room.requiredZone.exit = exit
            else
                self.room.requiredZone.entrance = exit
            end
        end

        rectangle.center = self.room.requiredZone.exit:get_position()

        local orientation = get_orientation_of_exits(self.room.exits)
        print('room orientation:', orientation)

        if orientation == 'horizontal' then
            -- Make a somewhat vertical rectangle
            rectangle.w = math.random(3, 10)
            rectangle.h = math.random(10, 15)
        elseif orientation == 'vertical' then
            -- Make a somewhat horizontal rectangle
            rectangle.w = math.random(10, 15)
            rectangle.h = math.random(3, 10)
        elseif orientation == 'diagonal' then
            -- Make a somewhat square rectangle
            rectangle.w = math.random(5, 10)
            rectangle.h = math.random(5, 10)
        end

        table.insert(self.lakeSources,
                     self.room.requiredZone.exit:get_doorway())
    else
        return
    end

    --print('rectangle size:', rectangle.w, rectangle.h)

    rectangle.x = math.floor(rectangle.center.x - (rectangle.w / 2))
    rectangle.y = math.floor(rectangle.center.y - (rectangle.h / 2))

    --print('old rectangle position:', rectangle.x, rectangle.y)
    rectangle = keep_rectangle_onscreen(rectangle)
    --print('new rectangle position:', rectangle.x, rectangle.y)

    -- Mark off the rectangle of tiles to make more room for the object.
    for y = rectangle.y, rectangle.y + (rectangle.h - 1) do
        for x = rectangle.x, rectangle.x + (rectangle.w - 1) do
            self:add_occupied_tile({x = x, y = y})
            table.insert(self.zoneTiles, {x = x, y = y})
        end
    end
end

function RoomBuilder:add_lakes()
    for _, source in pairs(self.lakeSources) do
        local entrance = self.room.requiredZone.entrance
        local exit = self.room.requiredZone.exit

        -- Use a floodfilling algorithm to place water tiles starting at the
        -- entrance
        local waterTiles = self:lake_fill(exit, entrance)

        -- If we are in the roombuilder thread
        if self.isInThread then
            -- Don't try to create a real Lake object, since the Lake
            -- constructor uses too many variables/functions which are not
            -- accessible from the thread
            table.insert(self.lakes, {tiles = waterTiles})
        else
            table.insert(self.lakes, Lake(waterTiles))
        end

        -- Add the hotLava tiles to zoneTiles so we can see them in debug mode
        --for _, t in pairs(hotLava) do
        --    table.insert(self.zoneTiles, t)
        --end
    end
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
    self:add_required_zone()
    self:plot_walls()
    self:cleanup_untouchable_bricks()
    self:add_lakes()
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
    self.room.occupiedTiles = self.occupiedTiles
    self.room.midPoint = self.midPoint
    self.room.midPaths = self.midPaths
    self.room.zoneTiles = self.zoneTiles
    self.room.lakes = self.lakes

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
                table.insert(newBricks, b)
                break
            end
        end
    end
    self.bricks = newBricks

    -- If we have any lakes
    --if #self.lakes > 0 then
    --    -- Remove all water tiles from freeTiles
    --    local newFreeTiles = {}
    --    for _, ft in pairs(self.freeTiles) do
    --        local ok = true

    --        for _, lake in pairs(self.lakes) do
    --            for _, wt in pairs(lake.tiles) do
    --                if tiles_overlap(ft, wt) then
    --                    ok = false
    --                    break
    --                end
    --            end
    --        end

    --        if ok then
    --            table.insert(newFreeTiles, ft)
    --        end
    --    end
    --    self.freeTiles = newFreeTiles
    --end
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
        --local src = {x = e.x, y = e.y}
        --if src.y == -1 then
        --    src.y = src.y + 1
        --elseif src.x == ROOM_W then
        --    src.x = src.x - 1
        --elseif src.y == ROOM_H then
        --    src.y = src.y - 1
        --elseif src.x == -1 then
        --    src.x = src.x + 1
        --end

        local cpf = CheapPathFinder(e:get_doorway(), self.midPoint,
                                    {x1 = 0, y1 = 0,
                                     x2 = ROOM_W - 1, y2 = ROOM_H - 1})
        local tiles = cpf:plot()

        -- Append these tiles to occupiedTiles and midPaths
        for _, t in pairs(tiles) do
            self:add_occupied_tile({x = t.x, y = t.y})
            table.insert(self.midPaths,
                         {x = t.x, y = t.y})
        end

        --if DEBUG then
        --    table.insert(self.room.debugTiles, {x = e.x, y = e.y})
        --    for _, t in pairs(tiles) do
        --        table.insert(self.room.debugTiles, t)
        --    end
        --end
    end
end

function RoomBuilder:plot_walls()
    -- Make wall from right doorframe of each exit to left doorframe of next
    -- exit
    for i, exit in ipairs(self.exits) do
        local src = exit:get_doorframes()[2]

        local dest
        -- If there is another exit to connect to
        if self.exits[i + 1] ~= nil then
            -- Set the next exit's left doorframe as the destination
            dest = self.exits[i + 1]:get_doorframes()[1]
        else
            -- Set the first exit's left doorframe as the destination
            dest = self.exits[1]:get_doorframes()[1]
        end

        -- Find all vacant tiles accessible from the source doorframe
        local ff = FloodFiller(src, self.occupiedTiles)
        exit.freeTiles = ff:flood()

        --for k, v in pairs(self.occupiedTiles) do
        --    for k2, v2 in pairs(self.occupiedTiles) do
        --        if k ~= k2 and v.x == v2.x and v.y == v2.y then
        --            print('* redundant hotLava: ' .. v.x, v.y)
        --        end
        --    end
        --end

        -- Remove dest from freeTiles
        for j, t in pairs(exit.freeTiles) do
            if tiles_overlap(t, dest) then
                table.remove(exit.freeTiles, j)
                break
            end
        end

        --local intermediatePoint
        --intermediatePoint = true

        local destinations = {}
        --if intermediatePoint then
            -- Find a free tile which is close to an occupied tile
            for _, t in pairs(exit.freeTiles) do
                if manhattan_distance(t, self.midPoint) <= 5 then
                    table.insert(destinations, t)
                    break
                end
            end
        --end

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
        local nav = Navigator(src, destinations, self.occupiedTiles)
        local tiles = nav:plot()

        -- Make bricks at these coordinates
        for _, b in pairs(tiles) do
            local newBrick = Brick(b)
            newBrick.fromWall = exit:get_direction()

            table.insert(self.bricks, newBrick)
        end
    end
end


-- Non-Class Functions
function keep_rectangle_onscreen(rectangle)
    while true do
        if rectangle.x < 1 then
            rectangle.x = rectangle.x + 1
        elseif rectangle.x + (rectangle.w - 1) > (ROOM_W - 1) - 1 then
            rectangle.x = rectangle.x - 1
        elseif rectangle.y < 1 then
            rectangle.y = rectangle.y + 1
        elseif rectangle.y + (rectangle.h - 1) > (ROOM_H - 1) - 1 then
            rectangle.y = rectangle.y - 1
        else
            break
        end
    end

    return rectangle
end

-- This function only works if the room has exactly two exits, e.g. a
-- roadblocked room
function get_orientation_of_exits(exits)
    local d1 = exits[1]:get_direction()
    local d2 = exits[2]:get_direction()

    if (d1 == 1 or d1 == 3) and (d2 == 1 or d2 == 3) then
        return 'vertical'
    elseif (d1 == 2 or d1 == 4) and (d2 == 2 or d2 == 4) then
        return 'horizontal'
    else
        return 'diagonal'
    end
end

-- Floodfill starting from the exit, but in such a way that the entrance is not
-- blocked
function RoomBuilder:lake_fill(exit, entrance)
    -- Decide on a good maximum amount of water to allow, based on the
    -- room's size
    local maxTiles = #self.freeTiles * .33

    -- Place the waterTiles
    local waterTiles = {}
    local src = exit:get_doorway()
    local lateralDirs = perpendicular_directions(exit:get_direction())
    repeat
        local previousRow = row
        local row = extend_to_lava(src, lateralDirs, self.bricks)

        -- Check if one of the tiles in this row is touching the entrance
        for _, t in pairs(row) do
            if tiles_overlap(t, entrance:get_doorway()) then
                -- Don't use this row
                row = nil
                break
            end
        end

        if row then
            -- Make sure there are at least two water tiles that can be touched
            -- from the entrance
            local testWaterTiles = concat_tables({waterTiles, row})
            local numTouching = 0
            local ff = FloodFiller(entrance:get_doorway(),
                                   concat_tables({self.bricks,
                                                  testWaterTiles}))
            for _, t in pairs(ff:flood()) do
                for _, wt in pairs(testWaterTiles) do
                    if tiles_touching(t, wt) then
                        numTouching = numTouching + 1
                        break
                    end
                end
                if numTouching == 2 then
                    break
                end
            end

            if numTouching < 2 and #row >= 2 then
                print('only ' .. numTouching .. ' water tiles in this row ' ..
                      'are accessible from the entrance; rejecting row')
                row = nil
            end
        end

        if not row then
            break
        end

        -- Add this row to the hotLava for the water floodfill
        waterTiles = concat_tables({waterTiles, row})

        if previousRow then
            if #row == #previousRow and #waterTiles > maxTiles then
                break
            end
        end

        src = add_direction(src, opposite_direction(exit:get_direction()))
    until tile_in_table(src, self.bricks)

    return waterTiles
end
