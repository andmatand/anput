require('class.camel')
require('class.exit')
require('class.falsebrick')
require('class.khnum')
require('class.mapdisplay')
require('class.monster')
require('class.pathfinder')
require('class.room')
require('class.switch')
require('class.thunderstaff')
require('class.trader')
require('class.weapon')
require('class.wizard')
require('util.tables')
require('util.tile')

-- A Map generates a random contiguous layout of rooms and their exits
Map = class('Map')

function Map:init(args)
    self.game = args.game
end

function Map:generate()
    self:generate_path()
    self:add_roadblocks()
    self:add_branches()

    -- Combine the path and branches into one table
    self.nodes = concat_tables({self.path, self.branches})

    self:add_first_secret_room()
    self.rooms = self:generate_rooms()
    self:add_temple_exit()

    self:add_secret_rooms()
    self:add_doors()
    self:add_required_objects()
    self:add_hieroglyphs()

    -- Create a display of this map
    self.display = MapDisplay(self)

    return self.rooms
end

-- Add a secret-room node somewhere before the first roadblock
function Map:add_first_secret_room()
    local firstRoadblockDist = self.roadblocks[1].node.distanceFromStart

    -- Make a working copy of the nodes
    local nodes = copy_table(self.nodes)

    while #nodes > 0 do
        local index = math.random(1, #nodes)
        local node = nodes[index]

        if node.distanceFromStart > 1 and
           node.distanceFromStart < firstRoadblockDist then
            local neighbors = find_neighbor_tiles(node, self.nodes,
                                                  {diagonals = false})
            for _, neighbor in pairs(neighbors) do
                if not neighbor.occupied then
                    local neighbs = find_neighbor_tiles(neighbor, self.nodes,
                                                        {diagonals = false})
                    local ok = true
                    for _, pos in pairs(neighbs) do
                        if pos.occupied and not tiles_overlap(pos, node) then
                            ok = false
                            break
                        end
                    end

                    if ok then
                        -- Add a new node here
                        local newNode = {x = neighbor.x, y = neighbor.y}
                        newNode.distanceFromStart = node.distanceFromStart + 1
                        newNode.firstSecretRoom = true
                        table.insert(self.nodes, newNode)

                        return
                    end
                end
            end
        end

        table.remove(nodes, index)
    end

    print('OOPS: failed to find position for first secret room')
    love.event.quit()
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

    -- If this node will contain a roadblock
    if src.roadblock then
        -- Don't allow any branches from it
        return {}
    end

    -- Keep only neighbors that are empty and not touching any other tile
    local temp = {}
    for _, n in pairs(neighbors) do
        local ok = true

        if n.occupied then
            ok = false

        -- Don't let any branch tile touch the first or last rooms
        elseif tiles_touching(n, self.path[1]) or
               tiles_touching(n, self.path[#self.path]) then
            ok = false

        -- Don't go outside the canvas
        elseif n.x < self.canvas.x1 or n.y < self.canvas.y1 or
           n.x > self.canvas.x2 or n.y > self.canvas.y2 then
            ok = false
        end

        for _, p in pairs(allOtherNodes) do
            -- If this neighbor is touching one of the existing nodes
            if tiles_touching(n, p) then
                -- If the node has a roadblock
                if p.roadblock then
                    ok = false
                    break
                else
                    -- Check the main path to see if there is a roadblock node
                    -- between these two
                    for _, p2 in pairs(self.path) do
                        if p2.roadblock then
                            if (p2.distanceFromStart >=
                                src.sourceNode.distanceFromStart and
                                p2.distanceFromStart <=
                                p.sourceNode.distanceFromStart) or
                               (p2.distanceFromStart >=
                                p.sourceNode.distanceFromStart and
                                p2.distanceFromStart <=
                                src.sourceNode.distanceFromStart) then
                                ok = false
                                break
                            end
                        end
                    end
                end
            end
            if not ok then
                break
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
    while (numBranches < #self.path * .25 or #self.branches < 40) and
          #startingTiles > 0 do
        -- Choose a random starting positon on the main path
        local start = table.remove(startingTiles,
                                   math.random(1, #startingTiles))
        start.sourceNode = start
        local neighbors = self:find_branch_neighbors(start)

        while #neighbors > 0 do
            -- Choose a random neighbor position and remove it from future use
            local pos = table.remove(neighbors, math.random(1, #neighbors))
            pos.sourceNode = start
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
                    pos.sourceNode = start
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
    -- Add "Anput" to the first room
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
    --rings[1] = {radius = math.floor((canvas.width / 2) * .9)}
    --rings[2] = {radius = math.floor((canvas.width / 2) * .5)}
    rings[1] = {radius = math.random(5, 8)}
    rings[1] = {radius = 5}
    rings[2] = {radius = 3}

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
        n.sourceNode = n
    end

    -- Make the canvas accessible to other methods
    self.canvas = canvas
end

function Map:generate_rooms()
    -- Make a new room for each node
    local rooms = {}
    for i, node in ipairs(self.nodes) do
        -- Add the new room and attach it to this node
        local r = Room({index = #rooms + 1, game = self.game})
        r.distanceFromStart = node.distanceFromStart
        table.insert(rooms, r)
        node.room = r
        r.roadblock = node.roadblock
        r.mapNode = node
        local neighbors = find_neighbor_tiles(node, self.nodes,
                                              {diagonals = false})

        -- Add exits to correct walls of room
        local exits = {}
        for j, n in ipairs(neighbors) do
            if n.occupied then
                local linkedExit

                local x = math.random(2, ROOM_W - 2)
                local y = math.random(2, ROOM_H - 2)
                if j == 1 then
                    y = -1 -- North

                    -- If this neighbor has already been converted into a room
                    -- with exits, use the position of its corresponding exit
                    if n.room then
                        linkedExit = n.room:get_exit({y = ROOM_H})
                        x = linkedExit.x
                    end
                elseif j == 2 then
                    x = ROOM_W -- East
                    if n.room then
                        linkedExit = n.room:get_exit({x = -1})
                        y = linkedExit.y
                    end
                elseif j == 3 then
                    y = ROOM_H -- South
                    if n.room then
                        linkedExit = n.room:get_exit({y = -1})
                        x = linkedExit.x
                    end
                elseif j == 4 then
                    x = -1 -- West
                    if n.room then
                        linkedExit = n.room:get_exit({x = ROOM_W})
                        y = linkedExit.y
                    end
                end

                local newExit = Exit({x = x, y = y, room = node.room})
                if linkedExit ~= nil then
                    linkedExit.targetRoom = node.room

                    newExit.targetRoom = n.room
                end
                --print('new exit:', newExit.x, newExit.y, newExit.roomIndex)

                table.insert(exits, newExit)
            end
        end

        -- Add the exits to the room we created
        node.room.exits = exits
    end

    -- Set the last room on the main path as the artifact room
    self.artifactRoom = self.path[#self.path].room

    for _, r in pairs(rooms) do
        -- Give the room a specifc random seed
        r.randomSeed = math.random(self.game.randomSeed + r.index)

        -- Assign difficulty to each room based on distance from first room
        -- compared to artifact room
        r.difficulty = math.floor((r.distanceFromStart /
                                   self.artifactRoom.distanceFromStart) * 100)

        if r.roadblock == 'lake' then
            -- Make sure the exits aren't too close together
            make_sure_exits_are_not_too_close(r.exits[1], r.exits[2])

            -- Find the exit that should be blocked
            local blockedExit = r.exits[1]
            for _, exit in pairs(r.exits) do
                -- If the room to which this exit leads is farther from the
                -- first room
                if exit.targetRoom.distanceFromStart >
                   blockedExit.targetRoom.distanceFromStart then
                    blockedExit = exit
                end
            end

            r.requiredZone = {name = 'lake',
                              dir = blockedExit:get_direction()}
        end
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

                if r.roadblock or r.requiredZone then
                    ok = false
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

                if r.roadblock then
                    ok = false
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

    -- Put a bow in one of the 5 earliest rooms
    local rooms = self:get_rooms_by_distance(1, 5, {isSecret = false})
    local bowRoom = rooms[math.random(1, #rooms)]
    local bow = Weapon('bow')
    table.insert(bowRoom.requiredObjects, bow)

    -- Put the wizard in one of the 5 earliest rooms
    local rooms = self:get_rooms_by_distance(1, 5, {isSecret = false})
    local wizardRoom = rooms[math.random(1, #rooms)]
    add_npc_to_room(Wizard(), wizardRoom)

    -- Add hkay "magician" to the wizard's room
    wizardRoom.requiredHieroglyphs = {{'h', 'ka', 'y', 'book', 'god'}}

    -- Check for objects that need to be added when certain roadblocks exist
    for _, room in pairs(self.rooms) do
        if room.roadblock == 'khnum' then
            -- Put Khnum in this room
            add_npc_to_room(Khnum(), room)

            -- Add the "Khnum" hieroglyphs to the room
            room.requiredHieroglyphs = {{'hnm', 'w', 'khnum'}}
        elseif room.roadblock == 'lake' then
            -- Add the "lake" hieroglyphs to the room
            room.requiredHieroglyphs = {{'water', 'lake'}}

            -- Put the camel in a room somewhere before the lake
            local rooms
            rooms = self:get_rooms_by_distance(2, room.distanceFromStart - 1,
                                               {isSecret = false})
            add_npc_to_room(Camel(), rooms[math.random(1, #rooms)])
        end
    end

    -- Create a table of the rooms lower than the difficulty at which ghosts
    -- would spawn
    local easyRooms = self:get_rooms_by_difficulty(0,
                           MONSTER_DIFFICULTY['ghost'] / 2,
                           {isSecret = false})
    --local easyRoomsCopy = copy_table(easyRooms)
    local numShinyThings = 0
    while numShinyThings < 7 do
        -- Pick a random early room
        local roomNum = math.random(1, #easyRooms)

        -- If this is not the first room
        if easyRooms[roomNum].index ~= 1 then
            -- Add a shiny thing as a required object
            numShinyThings = numShinyThings + 1
            local item = Item('shinything')
            table.insert(easyRooms[roomNum].requiredObjects, item)

            -- Remove this room from consideration
            --table.remove(easyRoomsCopy, roomNum)

            -- If we ran out of easy rooms
            --if #easyRooms == 0 then
            --    -- Get the list again
            --    easyRoomsCopy = copy_table(easyRooms)
            --end
        end
    end

    -- Put the ankh in the artifact room
    table.insert(self.artifactRoom.requiredObjects, Item('ankh'))
end

function Map:add_roadblocks()
    local numRoadblocks = 2

    local roadblockTypes = {'khnum', 'lake'}

    -- Pick which roadblocks to use
    local roadblocks = {}
    for i = 1, numRoadblocks do
        roadblocks[i] = table.remove(roadblockTypes,
                                     math.random(1, #roadblockTypes))
    end

    -- Find positions on the main path for the roadblocks
    local r = 1 -- Keep track of which roadblock number we are on
    for _, node in pairs(self.path) do
        local targetDistance = math.floor(#self.path *
                                          ((1 / (#roadblocks + 1)) * r))

        -- If this node is the correct percentage distance from the first room
        -- to the last room in the path
        if node.distanceFromStart == targetDistance then
            -- Add the next roadblock to this room
            node.roadblock = roadblocks[r]

            -- Cache some info about this roadblock
            if not self.roadblocks then self.roadblocks = {} end
            self.roadblocks[r] = {node = node, roadblockType = roadblocks[r]}

            r = r + 1
            if r > #roadblocks then
                break
            end
        end
    end

    -- DEBUG: put a lake in the second room
    --self.path[2].roadblock = 'lake'
end

function Map:add_secret_rooms()
    -- Mark any qualified rooms as secret rooms
    for _, r in pairs(self.rooms) do
        -- If this room has only 1 exit and is not the first room or the
        -- artifact room
        if #r.exits == 1 and r.distanceFromStart > 0 and
           not r.artifactRoom then
            -- Put a false brick in front of the exit that leads to this room
            local adjacentRoom = r.exits[1].targetRoom
            local adjacentExit = adjacentRoom:get_exit({targetRoom = r})
            local falseBrick = FalseBrick(adjacentExit:get_doorway())
            table.insert(adjacentRoom.requiredObjects, falseBrick)

            -- Mark this room as a secret room
            r.isSecret = true
        end
    end
end

function Map:add_doors()
    for _, r in pairs(self.rooms) do
        -- If this room is not the first room or the artifact room
        if r.distanceFromStart > 0 and not r.artifactRoom and
           math.random(1, 1) == 1 and not r.isSecret then
           -- Choose one of the exits in this room
           local exits = copy_table(r.exits)
           local exit = nil
           while #exits > 0 do
               local index = math.random(1, #exits)
               local e = exits[index]

               -- If this exit is already concealed (e.g. by a falsebrick) or
               -- its linked exit is already concealed, or this exit leads to a
               -- secret room
               if e:is_hidden() or e:get_linked_exit():is_hidden() or
                  e.targetRoom.isSecret then
                   -- Remove it from future consideration
                   table.remove(exits, index)
               else
                   exit = e
                   break
               end
           end
           
           -- If we have chosen an exit
           if exit then
               -- Put a door in front of the exit and in front of its linked
               -- exit

               local insideDoor = Door(exit:get_doorway(),
                                       exit:get_direction())
               exit.room:add_object(insideDoor)

               local linkedExit = exit:get_linked_exit()
               local outsideDoor = Door(linkedExit:get_doorway(),
                                        linkedExit:get_direction())
               linkedExit.room:add_object(outsideDoor)

               outsideDoor:set_sister(insideDoor)
               insideDoor:set_sister(outsideDoor)

               local room1, room2, door1
               if exit.room.distanceFromStart <
                  linkedExit.room.distanceFromStart then
                   room1 = exit.room
                   room2 = linkedExit.room
                   door1 = insideDoor
               else
                   room1 = linkedExit.room
                   room2 = exit.room
                   door1 = outsideDoor
               end

               local switch = Switch(door1)
               room1:add_object(switch)
           end
       end
   end
end

function Map:update()
    self.display:update()
end


-- Non-Class Functions
function add_npc_to_room(npc, room)
    table.insert(room.requiredObjects, npc)
    if room.requiredZone then
        print(room.index)
        print('OOPS: room already has requiredZone ' ..
              room.requiredZone.name .. ' but we are trying to set it to npc')
        love.event.quit()
    end
    room.requiredZone = {name = 'npc'}
end


function make_sure_exits_are_not_too_close(exit1, exit2)
    if math.abs(exit2.y - exit1.y) < 6 then
        print('exits are too close on y axis; moving them')
        -- Find the exit that is able to be moved on the y axis (i.e.
        -- it is on the east or west wall)
        for _, exit in pairs({exit1, exit2}) do
            if exit:get_direction() == 2 or exit:get_direction() == 4 then
                if exit.y < 10 then
                    exit.y = exit.y + 10
                else
                    exit.y = exit.y - 10
                end

                -- Also move the exit to which this one leads
                exit:get_linked_exit().y = exit.y

                break
            end
        end
    elseif math.abs(exit2.x - exit1.x) < 6 then
        print('exits are too close on x axis; moving them')
        -- Find the exit that is able to be moved on the x axis (i.e. it is on
        -- the north or south wall)
        for _, exit in pairs({exit1, exit2}) do
            if exit:get_direction() == 1 or exit:get_direction() == 3 then
                if exit.x < 10 then
                    exit.x = exit.x + 10
                else
                    exit.x = exit.x - 10
                end

                -- Also move the exit to which this one leads
                exit:get_linked_exit().x = exit.x

                break
            end
        end
    end
end
