require('util.tables')

function add_direction(tile, dir, distance)
    -- Distance defauls to 1
    local dist = distance or 1

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

function box_area(box)
    return ((box.x2 - box.x1) + 1) * ((box.y2 - box.y1) + 1)
end

function combine_tile_tables(tables)
    local newTable = {}
    local count = 0

    for i = 1, #tables do
        local tbl = tables[i]

        for j = 1, #tbl do
            local tile = tbl[j]

            local ok = true
            if i > 1 then
                for k = 1, count do
                    -- If this tile has already been added to the new table
                    if tiles_overlap(tile, newTable[k]) then
                        ok = false
                    end
                end
            end

            if ok then
                count = count + 1
                newTable[count] = tile
            end
        end
    end

    return newTable
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

function directions_to(from, to)
    local dirs = {}
    if to.y < from.y then
        -- North
        table.insert(dirs, 1)
    end
    if to.x > from.x then
        -- East
        table.insert(dirs, 2)
    end
    if to.y > from.y then
        -- South
        table.insert(dirs, 3)
    end
    if to.x < from.x then
        -- South
        table.insert(dirs, 4)
    end

    return dirs
end

function extend_to_lava(src, dirs, lavaCache)
    local tiles = {}
    table.insert(tiles, src)

    for _, dir in pairs(dirs) do
        local pos = src

        while true do
            pos = add_direction(pos, dir)

            local ok = true

            if #lavaCache:get_tile(pos).contents > 0 then
                ok = false
            end

            if pos.x < 0 or pos.y < 0 or
               pos.x > ROOM_W - 1 or pos.y > ROOM_H - 1 then
                ok = false
            end

            if ok then
                table.insert(tiles, pos)
            else
                break
            end
        end
    end

    return tiles
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
                    n.room = o.room -- Dirty hack for map:generate_rooms()
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

function is_corner_tile(tile, otherTiles)
    return consecutive_free_neighbors(tile, otherTiles, 4)
end

function manhattan_distance(a, b)
    return math.abs(b.x - a.x) + math.abs(b.y - a.y)
end

function num_neighbor_tiles(tile, otherTiles)
    local neighbors = find_neighbor_tiles(tile, otherTiles,
                                          {countBorders = true})
    local num = 0
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

function remove_duplicate_tiles(tiles)
    local newTiles = {}
    for _, t in pairs(tiles) do
        local ok = true
        for _, t2 in pairs(newTiles) do
            if tiles_overlap(t, t2) then
                ok = false
            end
        end

        if ok then
            table.insert(newTiles, t)
        end
    end

    return newTiles
end

function remove_tiles_from_table(tiles, fromTable)
    local newTable = {}
    for _, t in pairs(fromTable) do
        local ok = true
        for _, t2 in pairs(tiles) do
            if tiles_overlap(t, t2) then
                ok = false
                break
            end
        end

        if ok then
            table.insert(newTable, t)
        end
    end

    return newTable
end

function find_box_surrounding(tiles)
    local x1, y1, x2, y2

    for _, tile in pairs(tiles) do
        if not y1 or tile.y < y1 then
            y1 = tile.y
        end
        if not x1 or tile.x < x1 then
            x1 = tile.x
        end
        if not y2 or tile.y > y2 then
            y2 = tile.y
        end
        if not x2 or tile.x > x2 then
            x2 = tile.x
        end
    end

    return {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function tables_have_overlapping_tiles(tbl1, tbl2)
    for i = 1, #tbl1 do
        local t1 = tbl1[i]

        for j = 1, #tbl2 do
            local t2 = tbl2[j]

            if tiles_overlap(t1, t2) then
                return true
            end
        end

    end
end

function tile_in_table(tile, tbl)
    for i = 1, #tbl do
        local t = tbl[i]

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

function plot_circle(position, radius)
    local x0 = position.x
    local y0 = position.y

    local nodes = {}
    local f = 1 - radius
    local ddf_x = 1
    local ddf_y = -2 * radius
    local x = 0
    local y = radius
    table.insert(nodes, {x = x0, y = y0 - radius}) -- North
    table.insert(nodes, {x = x0 + radius, y = y0}) -- East
    table.insert(nodes, {x = x0, y = y0 + radius}) -- South
    table.insert(nodes, {x = x0 - radius, y = y0}) -- West

    while x < y do
        if f >= 0 then
            y = y - 1
            ddf_y = ddf_y + 2
            f = f + ddf_y
        end

        x = x + 1
        ddf_x = ddf_x + 2
        f = f + ddf_x

        table.insert(nodes, {x = x0 + x, y = y0 + y})
        table.insert(nodes, {x = x0 - x, y = y0 + y})
        table.insert(nodes, {x = x0 + x, y = y0 - y})
        table.insert(nodes, {x = x0 - x, y = y0 - y})
        table.insert(nodes, {x = x0 + y, y = y0 + x})
        table.insert(nodes, {x = x0 - y, y = y0 + x})
        table.insert(nodes, {x = x0 + y, y = y0 - x})
        table.insert(nodes, {x = x0 - y, y = y0 - x})
    end

    nodes = remove_duplicate_tiles(nodes)

    return nodes
end
