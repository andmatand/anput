require('class/falsebrick')
require('class/exit')
require('class/mapdisplay')
require('class/pathfinder')
require('class/room')
require('class/trader')
require('class/trader')
require('class/weapon')
require('util/tables')
require('util/tile')

-- A Map generates a random contiguous layout of rooms and their exits
Map = class('Map')

function Map:init(args)
    self.game = args.game
end

function Map:generate()
    self.path = self:generate_path()
    self.branches = self:add_branches(self.path)
    self.display = nil

    self.rooms = self:generate_rooms()

    self:add_secret_passages()
    self:add_required_objects()

    return self.rooms
end

function move_random(node)
    if math.random(0, 1) == 0 then
        -- Move x
        if math.random(0, 1) == 0 then
            node.x = node.x - 1
        else
            node.x = node.x + 1
        end
    else
        -- Move y
        if math.random(0, 1) == 0 then
            node.y = node.y - 1
        else
            node.y = node.y + 1
        end
    end
end

function find_empty_neighbors(node, otherNodesTables)
    -- Combine all tables in otherNodesTables
    allOtherNodes = concat_tables(otherNodesTables)

    neighbors = find_neighbor_tiles(node, allOtherNodes, {diagonals = false})

    -- Keep only empty neighbors
    temp = {}
    for j,n in pairs(neighbors) do
        ok = true

        if n.occupied == true then
            ok = false
        end

        if ok then
            table.insert(temp, n)
        end
    end
    neighbors = temp

    --print('empty neighbors:')
    --for j,n in pairs(neighbors) do
    --  print(n.x, n.y)
    --end

    return neighbors
end

function Map:add_branches(path)
    branches = {}
    for i,p in pairs(path) do
        -- Don't branch off from the final room
        if i == #path then break end

        --print('\npath node ' .. i .. ':', p.x, p.y)

        neighbors = find_empty_neighbors(p, {path, branches})

        for j,n in pairs(neighbors) do
            if math.random(0, 2) == 0 then
                -- Form a branch starting from this neighbor
                table.insert(branches, n)

                maxLength = math.random(1, 6)
                branchLength = 1
                tile = n
                while branchLength < maxLength do
                    possibleMoves = find_empty_neighbors(tile,
                                                         {path, branches})

                    if #possibleMoves > 0 then
                        -- Move randomly to one of the open neighbors
                        tile = possibleMoves[math.random(1, #possibleMoves)]
                        branchLength = branchLength + 1
                        table.insert(branches, tile)
                    else
                        break
                    end
                end
            end
        end
    end

    return branches
end

function Map:draw(currentRoom)
    self.display:draw(currentRoom)
end

function Map:generate_path()
    src = {x = 0, y = 0}

    -- Pick random location for the final room
    breadth = 15
    distance = {}
    distance.x = math.random(-breadth, breadth)
    distance.y = breadth - math.abs(distance.x)
    if math.random(0, 1) == 0 then
        distance.y = -distance.y
    end
    dest = {x = src.x + distance.x, y = src.y + distance.y}

    -- Find the rectangle of space between the two points
    rect = {}
    if src.x <= dest.x then
        rect.x1 = src.x
        rect.x2 = dest.x
    else
        rect.x1 = dest.x
        rect.x2 = src.x
    end
    if src.y <= dest.y then
        rect.y1 = src.y
        rect.y2 = dest.y
    else
        rect.y1 = dest.y
        rect.y2 = src.y
    end

    -- Place some obstacles in between the rooms
    self.obstacles = {}
    for i = 1,(breadth * 3) do
        x = math.random(rect.x1, rect.x2)
        y = math.random(rect.y1, rect.y2)

        ok = true
        if (x == src.x and y == src.y) or
           (x == dest.x and y == dest.y) then
           ok = false
        end

        if ok then
            table.insert(self.obstacles, {x = x, y = y})
        end
    end

    -- Plot path from src to dest through obstacles
    pf = PathFinder(src, dest, self.obstacles, nil, {bounds = false})
    path = pf:plot()
    path[#path].finalRoom = true

    return path
end

function Map:generate_rooms()
    -- Combine the path and branches into one table
    self.nodes = concat_tables({self.path, self.branches})

    -- Make a new room for each node
    rooms = {}
    for i,node in ipairs(self.nodes) do
        -- Add the new room and attach it to this node
        r = Room({exits = exits, index = #rooms + 1, game = self.game})
        r.distanceFromStart = manhattan_distance(node, self.path[1])
        table.insert(rooms, r)
        node.room = r

        neighbors = find_neighbor_tiles(node, self.nodes, {diagonals = false})

        -- Add exits to correct walls of room
        exits = {}
        for j,n in ipairs(neighbors) do
            if n.occupied then
                linkedExit = nil

                x = math.random(2, ROOM_W - 2)
                y = math.random(2, ROOM_H - 2)
                if j == 1 then
                    y = -1 -- North

                    -- If this neighbor has already been converted into a room
                    -- with exits, use the position of its corresponding exit
                    if n.room ~= nil then
                        linkedExit = n.room:get_exit({y = ROOM_H})
                        x = linkedExit.x
                    end
                elseif j == 2 then
                    x = ROOM_W -- East
                    if n.room ~= nil then
                        linkedExit = n.room:get_exit({x = -1})
                        y = linkedExit.y
                    end
                elseif j == 3 then
                    y = ROOM_H -- South
                    if n.room ~= nil then
                        linkedExit = n.room:get_exit({y = -1})
                        x = linkedExit.x
                    end
                elseif j == 4 then
                    x = -1 -- West
                    if n.room ~= nil then
                        linkedExit = n.room:get_exit({x = ROOM_W})
                        y = linkedExit.y
                    end
                end

                newExit = Exit({x = x, y = y})
                if linkedExit ~= nil then
                    linkedExit.roomIndex = #rooms
                    linkedExit.room = node.room

                    newExit.roomIndex = n.room.index
                    newExit.room = n.room
                end
                --print('new exit:', newExit.x, newExit.y, newExit.roomIndex)

                table.insert(exits, newExit)
            end
        end

        -- Add the exits to the room we created
        node.room.exits = exits
    end

    -- Find the room that's farthest away from the first room, and set it as
    -- the last room
    farthestDistance = 0
    for _, r in pairs(rooms) do
        if r.distanceFromStart > farthestDistance then
            farthestDistance = r.distanceFromStart
            self.lastRoom = r
        end
    end

    -- Assign difficulty to each room based on distance from first room
    -- compared to last room
    for _, r in pairs(rooms) do
        r.difficulty = math.floor((r.distanceFromStart /
                                    self.lastRoom.distanceFromStart) * 100)
    end

    -- Create a display of this map
    self.display = MapDisplay(self.nodes)

    return rooms
end

function Map:get_early_rooms(num)
    local earlyRooms = {}

    for distance = 1, 100 do
        for _, r in pairs(self.rooms) do
            if r.distanceFromStart == distance then
                table.insert(earlyRooms, r)

                if #earlyRooms == num then
                    return earlyRooms
                end
            end
        end
    end
end

function Map:get_rooms_below_difficulty(diff)
    local rooms = {}

    for _, r in pairs(self.rooms) do
        if r.difficulty < diff then
            table.insert(rooms, r)
        end
    end

    return rooms
end

function Map:add_required_objects()
    -- Put a sword in the starting room
    local sword = Weapon('sword')
    table.insert(self.rooms[1].requiredObjects, sword)

    -- Put a potion in the starting room
    --local potion = Item('potion')
    --table.insert(self.rooms[1].requiredObjects, potion)

    -- Create a table of the 5 earliest rooms
    local earlyRooms = self:get_early_rooms(5)

    -- Put the wizard in one of the 5 earliest rooms
    local chunk = love.filesystem.load('npc/wizard.lua')
    local wizard = chunk()
    while #earlyRooms > 0 do
        local roomNum = math.random(1, #earlyRooms)

        -- If this is a secret room
        if earlyRooms[roomNum].isSecret then
            -- Remove it from consideration
            table.remove(earlyRooms, roomNum)
        else
            table.insert(earlyRooms[roomNum].requiredObjects, wizard)
            break
        end
    end


    -- Create a table of the rooms lower than the difficulty at which ghosts
    -- would spawn
    local easyRooms = self:get_rooms_below_difficulty(
                      MONSTER_DIFFICULTY[MONSTER_TYPE.ghost])
    local numShinyThings = 0
    while numShinyThings < 7 do
        -- Pick a random early room
        local roomNum = math.random(1, #easyRooms)

        -- If this room doesn't already have too many reqiured objects
        if #easyRooms[roomNum].requiredObjects < 1 then
            -- Add a shiny thing as a required object
            numShinyThings = numShinyThings + 1
            table.insert(easyRooms[roomNum].requiredObjects,
                         Item('shinything'))
        else
            -- Otherwise remove this room from consideration
            table.remove(easyRooms, roomNum)
        end
    end

    -- Put the ankh in the last room
    table.insert(self.lastRoom.requiredObjects, Item('ankh'))
end

function Map:add_secret_passages()
    for _, r in pairs(self.rooms) do
        -- If this room has only 1 exit
        if r.distanceFromStart > 0 and #r.exits == 1 then
            -- Put a false brick in front of the exit that leads to this room
            local adjacentRoom = r.exits[1].room
            local adjacentExit = adjacentRoom:get_exit({room = r})
            local falseBrick = FalseBrick(adjacentExit:get_doorway())
            table.insert(adjacentRoom.requiredObjects, falseBrick)

            -- Mark this room as a secret room
            r.isSecret = true
        end
    end

    -- DEBUG: put false brick in first room
    --local exit = self.rooms[1].exits[1]
    ---- Put a false brick in front of the exit that leads to this room
    --local falseBrick = FalseBrick(exit:get_doorway())
    --table.insert(self.rooms[1].requiredObjects, falseBrick)
end

function Map:update()
    self.display:update()
end

