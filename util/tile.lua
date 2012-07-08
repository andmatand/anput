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

function find_neighbor_tiles(node, otherNodes, options)
    -- Make sure options is at least an empty table, so we can index it
    options = options or {}
    if options.diagonals == nil then
        -- Enable diagonals by default
        options.diagonals = true
    end

    -- Initialize all 8 neighbors' positions
    neighbors = {}
    for d = 1, 8 do
        local n = {occupied = false}
        if d == 1 then -- N
            n.x = node.x
            n.y = node.y - 1
        elseif options.diagonals and d == 2 then -- NE
            n.x = node.x + 1
            n.y = node.y - 1
        elseif d == 3 then -- E
            n.x = node.x + 1
            n.y = node.y
        elseif options.diagonals and d == 4 then -- SE
            n.x = node.x + 1
            n.y = node.y + 1
        elseif d == 5 then -- S
            n.x = node.x
            n.y = node.y + 1
        elseif options.diagonals and d == 6 then -- SW
            n.x = node.x - 1
            n.y = node.y + 1
        elseif d == 7 then -- W
            n.x = node.x - 1
            n.y = node.y
        elseif options.diagonals and d == 8 then -- NW
            n.x = node.x - 1
            n.y = node.y - 1
        end

        -- If this direction was not excluded
        if n.x then
            table.insert(neighbors, n)
        end
    end

    -- Check if any of the otherNodes are in the neighbor positions
    if otherNodes then
        for _, o in pairs(otherNodes) do
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
