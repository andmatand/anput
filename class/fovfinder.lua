require('util.tile')

local DEBUG = false

local function round(num)
    --return math.floor(num + .5)
    return math.floor(num)
end

local function slope(a, b)
    if (b.x - a.x) == 0 then
        return 0
    else
        return (b.y - a.y) / (b.x - a.x)
    end
end


-- A Cone is a triangle of vision (used as an octant)
local Cone = class('Cone')

function Cone:init(args)
    self.octant = args.octant
    self.origin = args.origin -- Must be a table keyed with {x, y}
    self.slope1 = args.slope1
    self.slope2 = args.slope2
end

-- Returns a column of tiles, rotated/translated to our octant.
-- colNums are:
--      #
--     ##
--    ###
--   ####
--   1234 etc.
function Cone:get_column(colNum)
    local tiles = {}
    local tileCount = 0
    local x, y, x1, x2, y1, y2

    -- Find the x, start y, and end y, based on (column number away from origin
    x = colNum - 1
    y1 = x * self.slope1
    y2 = x * self.slope2
    
    -- Round to nearest tile
    y1 = round(y1)
    y2 = round(y2)

    -- Create a table of tiles in a column, top to bottom
    for y = y1, y2 do
        tile = {x = x, y = y}

        -- If this is the last tile in the column
        if y == y2 then
            -- Mark it as such
            tile.last = true
        end

        tileCount = tileCount + 1
        tiles[tileCount] = tile
    end

    return tiles
end

-- Returns the coordinates so that they are relative to the origin
function Cone:translate_origin(tile)
    return {x = self.origin.x + tile.x, y = self.origin.y + tile.y}
end

function Cone:translate_octant(tile)
    if self.octant == 1 then
        return self:translate_origin({x = tile.y, y = -tile.x})
    elseif self.octant == 2 then
        return self:translate_origin({x = -tile.y, y = -tile.x})
    elseif self.octant == 3 then
        return self:translate_origin(tile)
    elseif self.octant == 4 then
        return self:translate_origin({x = tile.x, y = -tile.y})
    elseif self.octant == 5 then
        return self:translate_origin({x = -tile.y, y = tile.x})
    elseif self.octant == 6 then
        return self:translate_origin({x = tile.y, y = tile.x})
    elseif self.octant == 7 then
        return self:translate_origin({x = -tile.x, y = -tile.y})
    elseif self.octant == 8 then
        return self:translate_origin({x = -tile.x, y = tile.y})
    end
end


-- A FOV finder finds a Field Of View (collection of tiles which are visibile
-- from a point within a room)
FOVFinder = class('Fov')

function FOVFinder:init(args)
    self.origin = args.origin
    self.radius = args.radius
    self.room = args.room
    self.fov = args.fov or {}
end

function FOVFinder:find()
    self:shadow_cast()

    return self.fov
end

function FOVFinder:add_to_fov(tile)
    -- Make sure this position is not already in the FOV
    local fovCount = #self.fov
    local fov = self.fov
    for i = 1, fovCount do
        if tiles_overlap(tile, fov[i]) then
            return
        end
    end

    self.fov[fovCount + 1] = tile
end

function FOVFinder:shadow_cast()
    -- Octants
    -- \  |  /
    --  \1|2/
    --  8\|/3
    -- ---@---
    --  7/|\4
    --  /6|5\
    -- /  |  \

    -- Consider the origin visible
    --self:add_to_fov(self.origin)

    local origin
    local slope1
    local slope2
    for octant = 1, 8 do
    --for octant = 3, 3 do
        slope1 = -1
        slope2 = 0
        --if octant == 1 then
        --  origin = {x = self.origin.x - 1, y = self.origin.y - 1}
        --elseif octant == 2 then
        --  origin = {x = self.origin.x, y = self.origin.y - 1}
        --elseif octant == 3 then
        --  origin = {x = self.origin.x + 1, y = self.origin.y - 1}
        --elseif octant == 4 then
        --  origin = {x = self.origin.x + 1, y = self.origin.y}
        --elseif octant == 5 then
        --  origin = {x = self.origin.x + 1, y = self.origin.y + 1}
        --elseif octant == 6 then
        --  origin = {x = self.origin.x, y = self.origin.y + 1}
        --elseif octant == 7 then
        --  origin = {x = self.origin.x - 1, y = self.origin.y + 1}
        --elseif octant == 8 then
        --  origin = {x = self.origin.x - 1, y = self.origin.y}
        --end

        origin = self.origin

        local queue = {}

        -- If the origin for this octant is in the room
        --if self.room:tile_in_room(origin, {includeBricks = true}) then
            -- Create the first cone
            local cone = Cone({origin = origin,
                               octant = octant,
                               slope1 = slope1,
                               slope2 = slope2})

            -- Place the first cone on the scan-queue
            queue[#queue + 1] = {cone = cone, colNum = 1}

            -- DEBUG: draw all columns
            --for colNum = 1, self.radius do
            --    for _, tile in ipairs(cone:get_column(colNum)) do
            --        local transTile = cone:translate_octant(tile)

            --        love.graphics.setColor(255, 255, 255)
            --        love.graphics.setLine(1, 'rough')
            --        love.graphics.rectangle('line',
            --                                transTile.x * TILE_W,
            --                                transTile.y * TILE_H,
            --                                TILE_W, TILE_H)
            --    end
            --end
        --end

        if DEBUG then
            print()
            print('octant:', octant)
            print('origin:', origin.x, origin.y)
        end

        while #queue > 0 do
            local job = table.remove(queue)

            if DEBUG then
                print('colNum: ' .. job.colNum)
                print('  slope1: ' .. job.cone.slope1)
                print('  slope2: ' .. job.cone.slope2)
            end

            local sawAnyObstacles = false
            local sawAnyUnoccupied = false
            local previousTileWasOccupied = nil
            local newSlope1 = job.cone.slope1
            local newSlope2 = job.cone.slope2
            local column = job.cone:get_column(job.colNum)
            for i = 1, #column do
                local tile = column[i]

                local transTile = job.cone:translate_octant(tile)

                local occupied = false
                local roomTile = self.room:get_tile(transTile)
                for j = 1, #roomTile.contents do
                    if roomTile.contents[j].isFovObstacle then
                        occupied = true
                        break
                    end
                end

                if DEBUG then
                    print('  tile: ' .. tile.x .. ', ' .. tile.y)
                    print('  transTile: ' .. transTile.x .. ', ' ..
                          transTile.y)

                    print('  within radius: ' ..
                          tostring(self:within_radius(transTile)))
                    print('  tile in room: ' .. tostring(
                          self.room:tile_in_room(transTile)))
                end

                -- If this tile is within the viewing radius and in the room
                if (self:within_radius(transTile) and
                    self.room:tile_in_room(transTile)) then
                    -- Consider this tile visible
                    self:add_to_fov(transTile)
                else
                    occupied = true
                end

                if occupied then
                    if DEBUG then
                        print('    occupied')
                    end

                    sawAnyObstacles = true

                    if previousTileWasOccupied == false then
                        -- Find the slope to the top left of this tile
                        newSlope2 = slope({x = 0, y = 0},
                                          {x = tile.x, y = tile.y - 1})
                        if DEBUG then
                            print('    set newSlope2 to ' .. newSlope2)
                        end

                        local newCone = Cone({origin = origin,
                                              octant = octant,
                                              slope1 = newSlope1,
                                              slope2 = newSlope2})

                        -- Add another cone to the work queue with a slope2
                        -- of right above this tile
                        queue[#queue + 1] = {cone = newCone,
                                             colNum = job.colNum + 1}

                        if DEBUG then
                            print('    queue add:')
                            print('      newSlope1: ' .. newSlope1)
                            print('      newSlope2:' .. newSlope2)
                        end
                    end

                    previousTileWasOccupied = true
                else
                    sawAnyUnoccupied = true

                    if previousTileWasOccupied then
                        -- Find the slope to the bottom right of the previous
                        -- tile
                        newSlope1 = slope({x = 0, y = 0},
                                          {x = tile.x + 1, y = tile.y - .1})
                        
                        if DEBUG then
                            print('    set newSlope1 to ' .. newSlope1)
                        end
                    end

                    previousTileWasOccupied = false
                end

                -- If this is the last tile in the column
                if tile.last then
                    if not occupied and sawAnyUnoccupied then
                        if DEBUG then
                            print('    last:')
                            print('      adding cone:')
                            print('        slope1: ' .. newSlope1)
                            print('        slope2: ' .. newSlope2)
                        end

                        -- Add the next column to the queue
                        local newCone = Cone({origin = job.cone.origin,
                                              octant = job.cone.octant,
                                              slope1 = newSlope1,
                                              slope2 = newSlope2})

                        queue[#queue + 1] = {cone = newCone,
                                             colNum = job.colNum + 1}
                    end
                end
            end
        end
    end
end

function FOVFinder:within_radius(tile)
    -- If the distance from the center of the origin to the bottom left corner
    -- of the tile is less than the radius (zoom in 3x in calculation in order
    -- to pick in-between points)
    if distance({x = (self.origin.x * 3) + 1,
                 y = (self.origin.y * 3) + 1},
                {x = (tile.x * 3),
                 y = (tile.y * 3) + 1}) < self.radius * 3 then
        return true
    else
        return false
    end
end
