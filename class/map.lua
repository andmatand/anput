require('class.falsebrick')
require('class.exit')
require('class.thunderstaff')
require('class.mapdisplay')
require('class.monster')
require('class.pathfinder')
require('class.room')
require('class.trader')
require('class.weapon')
require('util.tables')
require('util.tile')

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
    self:add_temple_exit()

    self:add_secret_passages()
    self:add_required_objects()
    self:add_hieroglyphs()

    return self.rooms
end

function Map:add_temple_exit()
    -- Get the exit in the first room
    local exit = self.path[1].room.exits[1]

    if #self.path[1].room.exits > 1 then
        print('OOPS: first room has more than 1 exit')
        love.event.quit()
    end

    -- Find the wall opposite the first room's exit
    local dir = opposite_direction(exit:get_direction())

    local x = math.random(2, ROOM_W - 2)
    local y = math.random(2, ROOM_H - 2)

    if dir == 1 then
        -- North
        y = -1
    elseif dir == 2 then
        -- East
        x = ROOM_W
    elseif dir == 3 then
        -- South
        y = ROOM_H
    elseif dir == 4 then
        -- West
        x = -1
    end

    -- Add an exit to the first room which leads outside
    local newExit = Exit({x = x, y = y, room = self.rooms[1]})
    newExit.targetRoom = self.game.outside
    table.insert(self.rooms[1].exits, newExit)

    -- Ad an exit to the outside room which leads inside
    local exitToInside = Exit({x = -1, y = 10, room = self.game.outside})
    exitToInside.targetRoom = self.rooms[1]
    table.insert(self.game.outside.exits, exitToInside)
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
    local branches = {}
    for i, p in pairs(path) do
        -- Don't branch off from the first room or the final room
        if not (i == 1 or p.finalRoom) then
            --print('\npath node ' .. i .. ':', p.x, p.y)

            local neighbors = find_empty_neighbors(p, {path, branches})

            for j, n in pairs(neighbors) do
                if (math.random(0, 2) == 0 and
                    not tiles_touching(n, path[1])) then
                    -- Form a branch starting from this neighbor
                    table.insert(branches, n)

                    local maxLength = math.random(1, 6)
                    local branchLength = 1
                    local tile = n
                    while branchLength < maxLength do
                        possibleMoves = find_empty_neighbors(tile,
                                                             {path, branches})

                        if #possibleMoves > 0 then
                            -- Move randomly to one of the open neighbors
                            tile = possibleMoves[math.random(1,
                                                             #possibleMoves)]
                            if tiles_touching(tile, path[1]) then
                                break
                            end
                            branchLength = branchLength + 1
                            table.insert(branches, tile)
                        else
                            break
                        end
                    end
                end
            end
        end
    end

    return branches
end

function Map:add_hieroglyphs()
    -- Add inpwt "Anput" to the first room
    self.rooms[1].requiredHieroglyphs = {{'i', 'n_p', 'w', 't', 'goddess'}}

    -- DEBUG
    --self.rooms[2].requiredHieroglyphs = {{'s', 'tsh'}}
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
    path[1].firstRoom = true
    path[#path].finalRoom = true

    return path
end

function Map:generate_rooms()
    -- Combine the path and branches into one table
    self.nodes = concat_tables({self.path, self.branches})

    -- Make a new room for each node
    local rooms = {}
    for i, node in ipairs(self.nodes) do
        -- Add the new room and attach it to this node
        local r = Room({index = #rooms + 1, game = self.game})
        r.distanceFromStart = manhattan_distance(node, self.path[1])
        table.insert(rooms, r)
        node.room = r

        local neighbors = find_neighbor_tiles(node, self.nodes,
                                              {diagonals = false})

        -- Add exits to correct walls of room
        local exits = {}
        for j, n in ipairs(neighbors) do
            if n.occupied then
                linkedExit = nil

                local x = math.random(2, ROOM_W - 2)
                local y = math.random(2, ROOM_H - 2)
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

                newExit = Exit({x = x, y = y, room = node.room})
                if linkedExit ~= nil then
                    --linkedExit.roomIndex = #rooms
                    linkedExit.targetRoom = node.room

                    --newExit.roomIndex = n.room.index
                    newExit.targetRoom = n.room
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
    local farthestDistance = 0
    for _, r in pairs(rooms) do
        if r.distanceFromStart > farthestDistance then
            farthestDistance = r.distanceFromStart
            self.lastRoom = r
        end
    end

    for _, r in pairs(rooms) do
        -- Give the room a specifc random seed
        r.randomSeed = math.random(self.game.randomSeed + r.index +
                                   math.random(1, 1000))

        -- Assign difficulty to each room based on distance from first room
        -- compared to last room
        r.difficulty = math.floor((r.distanceFromStart /
                                    self.lastRoom.distanceFromStart) * 100)
    end

    -- Create a display of this map
    self.display = MapDisplay(self.nodes)

    return rooms
end

function Map:get_random_room(filters)
    local rooms = copy_table(self.rooms)

    if filters.distance then
        for _, r in pairs(rooms) do
            table.remove()
        end
    end
end

function Map:get_rooms_by_distance(min, max, filters)
    local rooms = {}

    for distance = min, max do
        for _, r in pairs(self.rooms) do
            local ok = true
            if filters then
                for k, v in pairs(filters) do
                    if r[k] ~= v then
                        ok = false
                        break
                    end
                end
            end

            if ok then
                if r.distanceFromStart == distance then
                    table.insert(rooms, r)
                end
            end
        end
    end

    return rooms
end

function Map:get_rooms_by_difficulty(min, max, filters)
    local rooms = {}

    for _, r in pairs(self.rooms) do
        local ok = true
        if filters then
            for k, v in pairs(filters) do
                if r[k] ~= v then
                    ok = false
                    break
                end
            end
        end

        if ok then
            if r.difficulty >= min and r.difficulty <= max then
                table.insert(rooms, r)
            end
        end
    end

    return rooms
end

function Map:add_required_objects()
    -- Put a sword in the starting room
    local sword = Weapon('sword')
    table.insert(self.rooms[1].requiredObjects, sword)

    -- DEBUG: Put a bunch of items in the starting room to fill up the
    -- inventory
    --table.insert(self.rooms[1].requiredObjects, Item('elixir'))
    --table.insert(self.rooms[1].requiredObjects, Item('shinything'))
    --table.insert(self.rooms[1].requiredObjects, Weapon('bow'))
    --table.insert(self.rooms[1].requiredObjects, Weapon('staff'))
    -- And then the ankh
    --table.insert(self.rooms[1].requiredObjects, Item('ankh'))

    -- DEBUG: Put a thing in the first room
    --local thing = Item('potion')
    --thing.tag = true
    --table.insert(self.rooms[1].requiredObjects, thing)

    -- Put the wizard in one of the 5 earliest rooms
    local rooms = self:get_rooms_by_distance(1, 5, {isSecret = false})
    local wizardRoom = rooms[math.random(1, #rooms)]
    add_npc_to_room(self.game.wizard, wizardRoom)

    -- Add hkay "magician" to the wizard's room
    wizardRoom.requiredHieroglyphs = {{'h', 'ka', 'y', 'book', 'god'}}
    

    -- Put the camel in a mid-difficulty room
    local rooms = self:get_rooms_by_difficulty(40, 60, {isSecret = false})
    add_npc_to_room(self.game.camel, rooms[math.random(1, #rooms)])

    -- Create a table of the rooms lower than the difficulty at which ghosts
    -- would spawn
    local easyRooms = self:get_rooms_by_difficulty(0,
                           MONSTER_DIFFICULTY['ghost'] - 1,
                           {isSecret = false})
    local easyRoomsCopy = copy_table(easyRooms)
    local numShinyThings = 0
    while numShinyThings < 7 do
        -- Pick a random early room
        local roomNum = math.random(1, #easyRoomsCopy)

        if easyRoomsCopy[roomNum].index ~= 1 then
            -- Add a shiny thing as a required object
            numShinyThings = numShinyThings + 1
            table.insert(easyRoomsCopy[roomNum].requiredObjects,
                         Item('shinything'))

            -- Remove this room from consideration
            table.remove(easyRoomsCopy, roomNum)

            -- If we ran out of easy rooms
            if #easyRooms == 0 then
                -- Get the list again
                easyRoomsCopy = copy_table(easyRooms)
            end
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
            local adjacentRoom = r.exits[1].targetRoom
            local adjacentExit = adjacentRoom:get_exit({targetRoom = r})
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


-- Non-Class Functions
function add_npc_to_room(npc, room)
    table.insert(room.requiredObjects, npc)
    room.needsRoomForNPC = true
end
