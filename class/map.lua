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
    self:generate_path()
    self:add_branches()

    self.rooms = self:generate_rooms()
    self:add_temple_exit()

    self:add_secret_passages()
    self:add_required_objects()
    self:add_hieroglyphs()

    -- Create a display of this map
    self.display = MapDisplay(self)

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

function Map:find_branch_neighbors(src)
    local allOtherNodes = concat_tables({self.path, self.branches})

    local neighbors = find_neighbor_tiles(src, allOtherNodes,
                                          {diagonals = false})

    -- Keep only neighbors that are empty and not touching any other tile
    local temp = {}
    for _, n in pairs(neighbors) do
        local ok = true

        if n.occupied then
            ok = false

        -- Don't let any branch tile touch the first room
        elseif tiles_touching(n, self.path[1]) then
            ok = false

        -- Don't go outside the canvas
        elseif n.x < self.canvas.x1 or n.y < self.canvas.y1 or
           n.x > self.canvas.x2 or n.y > self.canvas.y2 then
            ok = false
        end

        for _, n2 in pairs(allOtherNodes) do
            -- If this is not the starting node
            if not tiles_overlap(n2, src) then
                if tiles_touching(n, n2) then
                    ok = false
                    break
                end
            end
        end

        if ok then
            table.insert(temp, n)
        end
    end
    neighbors = temp

    return neighbors
end

function Map:add_branches()
    self.branches = {}
    --if self.branches then return end

    --local startingTiles = concat_tables({self.path, self.branches})
    local startingTiles = copy_table(self.path)

    local numBranches = 0
    while (numBranches < 10 or #self.branches < 40) and #startingTiles > 0 do
        -- Choose a random starting positon on the main path
        local start = table.remove(startingTiles,
                                   math.random(1, #startingTiles))
        local neighbors = self:find_branch_neighbors(start)

        while #neighbors > 0 do
            -- Choose a random neighbor position and remove it from future use
            local pos = table.remove(neighbors, math.random(1, #neighbors))
            pos.distanceFromStart = start.distanceFromStart + 1

            -- Form a branch starting from this position
            local newBranch = {}
            table.insert(newBranch, pos)
            numBranches = numBranches + 1

            local maxLength = 10--math.random(4, 10)
            while #newBranch < maxLength do
                local possibleMoves = self:find_branch_neighbors(pos)

                if #possibleMoves > 0 then
                    -- Move randomly to one of the open neighbors
                    pos = possibleMoves[math.random(1, #possibleMoves)]
                    pos.distanceFromStart =
                        newBranch[#newBranch].distanceFromStart + 1
                    table.insert(newBranch, pos)
                else
                    break
                end
            end

            -- Add the new branch to the main table of branches
            self.branches = concat_tables({self.branches, newBranch})
        end

        self.branches = remove_duplicate_tiles(self.branches)
    end
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
    -- Define the maximum available area for the map
    canvas = {}
    canvas.width = 15--23
    canvas.height = canvas.width
    canvas.x1 = 0
    canvas.y1 = 0
    canvas.x2 = canvas.width - 1
    canvas.y2 = canvas.height - 1
    canvas.center = {x = math.floor((canvas.x2 - canvas.x1) / 2),
                     y = math.floor((canvas.y2 - canvas.y1) / 2)}

    -- Define the radius for each ring
    local rings = {}
    --rings[1] = {radius = math.floor((canvas.width / 2) - 2)}
    --rings[2] = {radius = math.floor((canvas.width / 2) - 5)}
    --rings[3] = {radius = math.floor((canvas.width / 2) - 9)}
    rings[1] = {radius = math.floor((canvas.width / 2) * .9)}
    rings[2] = {radius = math.floor((canvas.width / 2) * .5)}
    --rings[3] = {radius = math.floor((canvas.width / 2) - 9)}

    -- Position the source somewhere outside ring 1
    local x = math.random(canvas.x1, canvas.x2)
    local y = math.random(canvas.y1, canvas.y2)
    local dir = math.random(1, 4)
    if dir == 1 then
        y = 0
    elseif dir == 2 then
        x = canvas.x2
    elseif dir == 3 then
        y = canvas.y2
    elseif dir == 4 then
        x = 0
    end
    local src = {x = x, y = y}

    -- Position the destination in the center
    local dest = {x = canvas.center.x, y = canvas.center.y}

    -- Starting with the path source position, choose sides of the rings on
    -- which to place a gap, always using the opposite side from the previous
    -- position
    local dir
    if src.y == canvas.y1 then
        dir = 1
    elseif src.x == canvas.x2 then
        dir = 2
    elseif src.y == canvas.y2 then
        dir = 3
    elseif src.x == canvas.x1 then
        dir = 4
    end
    for i = 1, #rings do
        dir = opposite_direction(dir)
        rings[i].gap = {side = dir}
    end

    -- Make hotLava nodes along each ring
    self.hotLava = {}
    for i, ring in pairs(rings) do
        local nodes = plot_circle(canvas.center, ring.radius)

        -- Choose a random gap position that is close to the middle node on
        -- the ring's gap.side
        local tmpNodes = copy_table(nodes)
        while #tmpNodes > 0 do
            local n = table.remove(tmpNodes, math.random(1, #tmpNodes))

            if manhattan_distance(n, nodes[ring.gap.side]) <= ring.radius then
                ring.gap.x = n.x
                ring.gap.y = n.y
                break
            end
        end

        for _, n in pairs(nodes) do
            if tiles_overlap(n, ring.gap) then
                -- Gap
            else
                table.insert(self.hotLava, n)
            end
        end
    end

    -- Plot path from src to dest through obstacles
    --local pf = PathFinder(src, dest, self.hotLava, nil, {bounds = false})
    local pf = PathFinder(src, dest, self.hotLava)
    self.path = pf:plot()

    -- Mark each room with its distance from the first room
    for i, n in pairs(self.path) do
        n.distanceFromStart = i - 1
    end

    -- Make the canvas accessible to other methods
    self.canvas = canvas
end

function Map:generate_rooms()
    -- Combine the path and branches into one table
    self.nodes = concat_tables({self.path, self.branches})

    -- Make a new room for each node
    local rooms = {}
    for i, node in ipairs(self.nodes) do
        -- Add the new room and attach it to this node
        local r = Room({index = #rooms + 1, game = self.game})
        r.distanceFromStart = node.distanceFromStart
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
    -- the artifact room
    local farthestDistance = 0
    for _, r in pairs(rooms) do
        if --r.distanceFromStart >= 60 and
           r.distanceFromStart > farthestDistance and
           #r.exits == 1 then
            farthestDistance = r.distanceFromStart
            self.artifactRoom = r
        end
    end

    for _, r in pairs(rooms) do
        -- Give the room a specifc random seed
        r.randomSeed = math.random(self.game.randomSeed + r.index +
                                   math.random(1, 1000))

        -- Assign difficulty to each room based on distance from first room
        -- compared to artifact room
        r.difficulty = math.floor((r.distanceFromStart /
                                   self.artifactRoom.distanceFromStart) * 100)
    end

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
    --self.game.camel.ai.level.globetrot = nil

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

    -- Put the ankh in the artifact room
    table.insert(self.artifactRoom.requiredObjects, Item('ankh'))
end

function Map:add_secret_passages()
    for _, r in pairs(self.rooms) do
        -- If this room has only 1 exit and is not the first room or the
        -- artifact room
        if #r.exits == 1 and r.distanceFromStart > 0 and not r.artifactRoom and
           math.random(0, 1) == 0 then -- Also mix in some randomness
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
