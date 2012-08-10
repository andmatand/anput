function add_direction(tile, dir, distance)
    -- Distance defauls to 1
    local dist = 1 or distance

    if dir == 1 then
        -- North
        return {x = tile.x, y = tile.y - dist}
    elseif dir == 2 then
        -- East
        return {x = tile.x + dist, y = tile.y}
    elseif dir == 3 then
        -- East
        return {x = tile.x, y = tile.y + dist}
    elseif dir == 4 then
        -- West
        return {x = tile.x - dist, y = tile.y}
    end
end

function direction_to(from, to)
    if to.y < from.y then
        -- North
        return 1
    elseif to.x > from.x then
        -- East
        return 2
    elseif to.y > from.y then
        -- South
        return 3
    elseif to.x < from.x then
        -- South
        return 4
    end
end

-- Returns a table of adjacent tile positions
function adjacent_tiles(tile, options)
    local options = options or {}
    local tiles = {}

    -- Initialize all 8 neighbors' positions
    for d = 1, 8 do
        local t = {}

        if d == 1 then -- N
            t.x = tile.x
            t.y = tile.y - 1
        elseif options.diagonals and d == 2 then -- NE
            t.x = tile.x + 1
            t.y = tile.y - 1
        elseif d == 3 then -- E
            t.x = tile.x + 1
            t.y = tile.y
        elseif options.diagonals and d == 4 then -- SE
            t.x = tile.x + 1
            t.y = tile.y + 1
        elseif d == 5 then -- S
            t.x = tile.x
            t.y = tile.y + 1
        elseif options.diagonals and d == 6 then -- SW
            t.x = tile.x - 1
            t.y = tile.y + 1
        elseif d == 7 then -- W
            t.x = tile.x - 1
            t.y = tile.y
        elseif options.diagonals and d == 8 then -- NW
            t.x = tile.x - 1
            t.y = tile.y - 1
        end

        -- If this direction was not excluded
        if t.x then
            table.insert(tiles, t)
        end
    end

    return tiles
end

-- Returns a table of adjacent tiles with marks on the ones which are in
-- occupied positions
function find_neighbor_tiles(node, occupiedNodes, options)
    -- Make sure options is at least an empty table, so we can index it
    local options = options or {}
    if options.diagonals == nil then
        -- Enable diagonals by default
        options.diagonals = true
    end

    -- Initialize all 8 neighbors' positions
    local neighbors = adjacent_tiles(node, options)
    for _, n in pairs(neighbors) do
        n.occupied = false
    end

    -- Check if any of the neighbor positions overlap with occupiedNodes
    if occupiedNodes then
        for _, o in pairs(occupiedNodes) do
            for _, n in pairs(neighbors) do
                if tiles_overlap(o, n) then
                    -- Mark this neighbor-tile as occupied
                    n.occupied = true
                    n.room = o.room
                end
            end
        end
    end

    if options.countBorders then
        -- Check if any of the neighbor positions touch the room border
        for i, n in pairs(neighbors) do
            if (n.y == 0 or n.x == ROOM_W - 1 or n.y == ROOM_H - 1 or
                n.x == 0) then
                n.occupied = true
            end
        end
    end

    return neighbors
end

function manhattan_distance(a, b)
    return math.abs(b.x - a.x) + math.abs(b.y - a.y)
end

function num_neighbor_tiles(tile, otherTiles)
    neighbors = find_neighbor_tiles(tile, otherTiles, {countBorders = true})
    num = 0
    for i,n in pairs(neighbors) do
        if n ~= nil then
            num = num + 1
        end
    end
    return num
end

function opposite_direction(dir)
    if dir == 1 then
        return 3
    elseif dir == 2 then
        return 4
    elseif dir == 3 then
        return 1
    elseif dir == 4 then
        return 2
    end
end

function consecutive_free_neighbors(tile, occupiedTiles, numInARow)
    -- Find the neighbor tiles
    local neighbors = find_neighbor_tiles(tile, occupiedTiles)

    -- Make sure there are at least <num> unoccupied
    -- clockwise-consecuitive neighbor tiles in a row
    local num = 0
    for _, n in ipairs(neighbors) do
        -- If we encounter an occupied tile
        if n.occupied then
            -- Reset the count to 0
            num = 0
        else
            num = num + 1
        end

        if num == numInARow then
            return true
        end
    end

    return false
end

function tile_in_table(tile, table)
    for i,t in pairs(table) do
        if t.position == nil then
            if tile.x == t.x and tile.y == t.y then
                return true
            end
        else
            if tile.x == t.position.x and tile.y == t.position.y then
                return true
            end
        end
    end
    return false
end

function tile_offscreen(tile)
    if tile.x < 0 or tile.x > ROOM_W - 1 or
       tile.y < 0 or tile.y > ROOM_H - 1 then
        return true
    else
        return false
    end
end

function tiles_overlap(a, b)
    -- If either of the tiles is not in a real position
    if a.x == nil or a.y == nil or b.x == nil or b.y == nil then
        return false
    end

    if a.x == b.x and a.y == b.y then
        return true
    else
        return false
    end
end

-- Returns true if tiles touch (non-diagonally) without overlapping
function tiles_touching(a, b)
    if (a.x == b.x and a.y == b.y - 1) or -- North
       (a.x == b.x + 1 and a.y == b.y) or -- East
       (a.x == b.x and a.y == b.y + 1) or -- South
       (a.x == b.x - 1 and a.y == b.y) then  -- West
        return true
    else
        return false
    end
end

-- Returns true if tiles touch diagonally without overlapping
function tiles_touching_diagonally(a, b)
    if (a.x == b.x + 1 and a.y == b.y - 1) or -- NE
       (a.x == b.x + 1 and a.y == b.y + 1) or -- SE
       (a.x == b.x - 1 and a.y == b.y + 1) or -- SW
       (a.x == b.x - 1 and a.y == b.y - 1) then   -- NW
        return true
    else
        return false
    end
end

function perpendicular_directions(dir)
    -- If the direction is north or south
    if dir == 1 or dir == 3 then
        -- Return west and east
        return {2, 4}

    -- If the direction is west or east
    elseif dir == 2 or dir == 4 then
        -- Return north and south
        return {1, 3}
    end
end
