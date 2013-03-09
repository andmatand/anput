require('class.hieroglyph')
require('class.item')
require('class.monster')
require('class.turret')
require('util.tile')
require('util.tables')

-- A RoomFiller fills a room with monsters, items, etc.
RoomFiller = class('RoomFiller')

function RoomFiller:init(room)
    self.room = room

    -- Make a table of tiles in which (walkable) items may be placed
    self.itemTiles = copy_table(self.room.freeTiles)
    
    -- Remove doorway tiles from future use
    for _, e in pairs(self.room.exits) do
        local dw = e:get_doorway()
        self:use_tile(dw)
    end

    -- Remove the room's midPoint from future use
    self:use_tile(self.room.midPoint)
end

function RoomFiller:fill_next_step()
    -- If this room contains a roadblock
    if self.room.roadblock then
        if self:add_required_objects() then
            if self:add_hieroglyphs() then
                if self:position_switches() then
                    return true
                end
            end
        end
    else
        if self:add_required_objects() then
            if self:add_hieroglyphs() then
                if self:add_turrets() then
                    if self:position_switches() then
                        if self:add_spikes() then
                            if self:add_monsters() then
                                if self:add_items() then
                                    -- Flag that room is done being filled
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Flag that room is not yet done being filled
    return false
end

function RoomFiller:add_hieroglyphs()
    if self.addedHieroglyphs then
        return true
    end

    if self.room.requiredHieroglyphs then
        for _, rh in pairs(self.room.requiredHieroglyphs) do
            for _, orientation in pairs({'horizontal', 'vertical'}) do
                if self:position_hieroglyph(rh, orientation) then
                    break
                end
            end
        end
    end

    self.addedHieroglyphs = true
    return false
end

function RoomFiller:position_switches()
    if self.positionedSwitches or not self.room.requiredSwitches then
        return true
    end

    local bricks = copy_table(self.room.bricks)
    local maxDistance = 5

    for _, switch in pairs(self.room.requiredSwitches) do
        while #bricks > 0 do
            local index = math.random(1, #bricks)
            local brick = bricks[index]

            local ok = false

            -- Make sure the brick is within the maximum distance
            local distance = manhattan_distance(brick:get_position(),
                                                switch.door:get_position())
            if distance <= maxDistance then
                -- Make sure the brick is touching a freetile
                for _, ft in pairs(self.room.freeTiles) do
                    if tiles_touching(brick:get_position(), ft) then
                        ok = true

                        -- Make sure this "freetile" is not actually a door
                        for _, door in pairs(self.room.doors) do
                            if tiles_overlap(door:get_position(), ft) then
                                ok = false
                                break
                            end
                        end

                        if ok then
                            break
                        end
                    end
                end
            end

            -- Make sure this position is not overlapping with a hieroglyph
            if ok then
                local tile = self.room.tileCache:get_tile(brick:get_position())
                if tile:contains_class(Hieroglyph) then
                    ok = false
                end
            end

            if ok then
                switch:set_position(brick:get_position())
                self.room:add_object(switch)
                break
            else
                -- Remove this brick from future consideration
                table.remove(bricks, index)

                -- If we have tried all bricks
                if #bricks == 0 then
                    -- If the switch still does not have a position
                    if not switch:get_position().x then
                        -- Increase the maxDistance and search again
                        maxDistance = maxDistance * 2
                        bricks = copy_table(self.room.bricks)
                    end
                end
            end
        end
    end

    self.positionedSwitches = true
    return false
end

function RoomFiller:add_spikes()
    if self.addedSpikes then
        return true
    end

    local minLength = 3
    local maxLength

    if self.room.difficulty < 5 or math.random(1, 3) ~= 1 then
        -- Do not put any spikes in this room
        self.addedSpikes = true
        return
    end

    -- Set the maximum number of spikes in a row, depending on the room's size
    -- and difficulty
    maxLength = math.random(0, #self.room.bricks * .02 *
                            (self.room.difficulty * .1))

    -- Determine a maximum length based on the room's difficulty
    --maxLength = math.floor(self.room.difficulty / 5)

    if maxLength < minLength then
        maxLength = minLength
    end

    local lines, dir1 = self:find_spike_positions(minLength, maxLength)
    for i, line in pairs(lines) do
        -- Determine which direction this line of spikes should point
        local dir
        if i == 1 then
            dir = dir1
        else
            dir = opposite_direction(dir1)
        end

        local lastPosition = {x = -1, y = -1}
        if dir == 3 then
            -- Find the spike that is farthest to the east
            for _, pos in pairs(line) do
                if pos.x > lastPosition.x then
                    lastPosition = pos
                end
            end
        elseif dir == 4 then
            -- Find the spike that is farthest to the south
            for _, pos in pairs(line) do
                if pos.y > lastPosition.y then
                    lastPosition = pos
                end
            end
        end

        -- Add a spike on each tile in this line
        for _, pos in pairs(line) do
            -- If this is the end spike pointing south or west
            if not tiles_overlap(pos, lastPosition) then
                self.room:add_object(Spike(pos, dir))
            end
        end
    end

    self.addedSpikes = true
    return false
end

function RoomFiller:find_spike_positions(minLength, maxLength)
    local lines = {{}, {}}

    test_tile = function(tile, room)
        -- If this tile does not contain only one brick
        local cachedTile = room.tileCache:get_tile(tile)
        if not (#cachedTile.contents == 1 and
                instanceOf(Brick, cachedTile.contents[1])) then
            return false, {}
        end

        local legalSpikeDirections = {}

        for dir = 1, 4 do
            for dist = 1, 2 do
                local pos = add_direction(tile, dir, dist)
                local cachedTile = room.tileCache:get_tile(pos)

                if dist == 1 then
                    -- If the tile is empty and inside the room, and is not a
                    -- doorway
                    if cachedTile.isPartOfRoom and not cachedTile.isDoorway and
                       #cachedTile.contents == 0 then
                    else
                        break
                    end
                elseif dist == 2 then
                    -- If the tile contains only a brick
                    if #cachedTile.contents == 1 and
                       instanceOf(Brick, cachedTile.contents[1]) then
                        table.insert(legalSpikeDirections, dir)
                    end
                end
            end
        end

        if #legalSpikeDirections > 0 then
            return true, legalSpikeDirections
        else
            return false, {}
        end
    end

    local bricks = copy_table(self.room.bricks)
    while #bricks > 0 do
        local index = math.random(1, #bricks)
        local sourceBrick = bricks[index]

        local ok, spikeDirections = test_tile(sourceBrick:get_position(),
                                              self.room)
        if not ok then
            -- Remove this brick from future use
            table.remove(bricks, index)
        end
        for _, spikeDir in pairs(spikeDirections) do
            -- Add the position of the source brick and its mate
            local pos = sourceBrick:get_position()
            table.insert(lines[1], pos)
            table.insert(lines[2], add_direction(pos, spikeDir, 2))

            -- Look for bricks next to this brick
            for _, lateralDir in pairs(perpendicular_directions(spikeDir)) do
                pos = sourceBrick:get_position()
                while true do
                    -- Move to the next tile in this direction
                    pos = add_direction(pos, lateralDir)

                    local ok, directions = test_tile(pos, self.room)

                    -- If this tile is an acceptable position for a spike
                    -- pointed in the same direction as the direction from the
                    -- source brick we are currently searching
                    if ok and value_in_table(spikeDir, directions) then
                        -- Add the spike positions to the lines
                        table.insert(lines[1], pos)
                        table.insert(lines[2], add_direction(pos, spikeDir, 2))
                    else
                        break
                    end
                end
            end

            if #lines[1] >= minLength then
                return lines, spikeDir
            end

            -- Remove the bricks in the lines from future use
            for _, line in pairs(lines) do
                for _, t in pairs(line) do
                    for i, b in pairs(bricks) do
                        if tiles_overlap(t, b) then
                            table.remove(bricks, i)
                            break
                        end
                    end
                end
            end

            -- Clear the lines
            lines[1] = {}
            lines[2] = {}
        end
    end

    return {}
end

function RoomFiller:give_random_items_to_monster(monster, possibleItemTypes)
    -- Choose a random item type
    local itemType = possibleItemTypes[math.random(1, #possibleItemTypes)]
    local num

    -- If this is an arrow
    if itemType == 'arrow' then
        -- Give the monster several arrows
        num = math.random(1, 10)
    else
        num = 1
    end

    for i = 1, num do
        local newItem = Item(itemType)

        -- Pretend the monster picked it up
        monster:pick_up(newItem)
    end
end

function RoomFiller:position_hieroglyph(letters, orientation)
    local dirs
    if orientation == 'horizontal' then
        dirs = {4, 2}
    elseif orientation == 'vertical' then
        dirs = {1, 3}
    end

    local goodBricks = {}
    for _, b in pairs(self.room.bricks) do
        local ok = false

        if orientation == 'horizontal' then
            -- If this brick has a freeTile below it
            local belowBrick = add_direction(b:get_position(), 3)
            local tile = self.room.tileCache:get_tile(belowBrick)
            if tile.isPartOfRoom then
                ok = true
            end
            for _, obj in pairs(tile.contents) do
                if instanceOf(Brick, obj) or instanceOf(Door, obj) then
                    ok = false
                end
            end
        else
            ok = true
        end

        -- If this brick already has something else on it
        local tile = self.room.tileCache:get_tile(b:get_position())
        if #tile.contents > 1 then
            -- It is not okay to use it
            ok = false
        end

        if ok then
            table.insert(goodBricks, b)
        end
    end

    -- Find a long enough row of bricks
    local padding = 1
    while #goodBricks > 0 do
        brick = goodBricks[math.random(1, #goodBricks)]

        local bricksInARow = {brick}
        local previousBrick = brick
        local removeBricks = false
        local dir = dirs[1]
        repeat
            local foundBrick = false
            for _, b2 in pairs(goodBricks) do
                -- If this other brick is 1 over in the direction we are
                -- searching
                if tiles_overlap(b2, add_direction(previousBrick, dir)) then
                    if dir == dirs[1] then
                        table.insert(bricksInARow, 1, b2)
                    elseif dir == dirs[2] then
                        table.insert(bricksInARow, b2)
                    end

                    foundBrick = true
                    previousBrick = b2
                    break
                end
            end

            if not foundBrick then
                if dir == dirs[1] then
                    -- Switch directions
                    dir = dirs[2]
                    previousBrick = brick

                -- If we didn't find enough bricks to fit all the letters
                elseif #bricksInARow < #letters + (padding * 2) then
                    removeBricks = true

                -- If we found enough bricks for all the letters
                elseif #bricksInARow >= #letters + (padding * 2) then
                    -- Find the starting brick that will make the string of
                    -- letters be centered
                    local start = math.floor((#bricksInARow / 2) -
                                             (#letters / 2)) + 1

                    -- Create the letters over the bricks
                    --for i, b in ipairs(bricksInARow) do
                    local letterIndex = 0
                    for i = start, start + #letters - 1 do
                        local b = bricksInARow[i]

                        letterIndex = letterIndex + 1

                        local newHieroglyph = Hieroglyph(b:get_position(),
                                                         letters[letterIndex])
                        self.room:add_object(newHieroglyph)
                    end
                    --removeBricks = true

                    -- We are done
                    return true
                end
            end

            if removeBricks then
                -- Remove the bricks we found from future consideration
                for _, b in pairs(bricksInARow) do
                    for i, gb in pairs(goodBricks) do
                        if tiles_overlap(gb, b) then
                            table.remove(goodBricks, i)
                            break
                        end
                    end
                end
                bricksInARow = {}

                break
            end
        until #goodBricks == 0
    end

    return false
end

function RoomFiller:add_items()
    if self.addedItems or self.room.index == 1 then
        return true
    end

    local itemTypes = self:get_item_types()

    -- If this is a secret room
    if self.room.isSecret then
        -- Add some goodies
        local numGoodies = math.random(4, 9)
        local goodies = {}

        for i = 1, numGoodies do
            -- Choose a random item type
            local itemType = itemTypes[math.random(1, #itemTypes)]

            -- If the type name is the name of a weapon type
            if WEAPON_TYPE[itemType] then
                table.insert(goodies, Weapon(itemType))

                -- Don't put any more of this weapon in this room
                remove_value_from_table(itemType, itemTypes)
            else
                table.insert(goodies, Item(itemType))
            end
        end

        -- Place the goodies in the room
        self:position_objects(goodies)
    else
        -- Give items to the monsters
        for _, m in pairs(self.room:get_monsters()) do
            if #itemTypes == 0 then
                break
            end

            if math.random(1, 3) == 1 then
                self:give_random_items_to_monster(m, itemTypes)
            end
        end

        -- Place items in nooks
        for _, nook in pairs(self.room.nooks) do
            if math.random(1, 2) == 1 then
                -- Choose a random item type
                local itemType = itemTypes[math.random(1, #itemTypes)]

                local newItem = Item(itemType)

                -- Position the item randomly in the nook
                newItem:set_position(nook[math.random(1, #nook)])

                self.room:add_object(newItem)
            end
        end
    end

    self.addedItems = true
    return false
end

function RoomFiller:add_monsters(max)
    local max = max or #self.room.freeTiles * .04

    if self.addedMonsters then
        -- Flag that this step was already completed
        return true
    end

    if self.room.isSecret and #self.room.exits == 1 then
        if math.random(1, 4) == 1 then
            -- Make this a snake den
            local numSnakes = math.random(#self.room.freeTiles * .1,
                                          #self.room.freeTiles * .2)

            local snakes = {}
            for i = 1, numSnakes do
                table.insert(snakes, Monster(self.room.game, 'cobra'))
            end
            self:position_objects(snakes)

            self.addedMonsters = true
            return false
        else
            return true
        end
    end

    -- Create a table of monsters with difficulties as high as possible in
    -- order to meet the room's difficulty level, without exceding the room's
    -- maximum occupancy
    local monsters = {}
    local totalDifficulty = 0
    while totalDifficulty < self.room.difficulty and #monsters < max do
        -- Find the hardest monster diffculty we still have room for
        local hardest = 0
        local monsterType = nil
        for mt, diff in pairs(MONSTER_DIFFICULTY) do
            if diff then
                if diff + totalDifficulty <= self.room.difficulty then
                    if diff > hardest then
                        hardest = diff
                        monsterType = mt
                    end
                end
            end
        end

        if monsterType then
            totalDifficulty = totalDifficulty + hardest
            table.insert(monsters, Monster(self.room.game, monsterType))
        end
    end

    -- DEBUG
    --print('actual difficulty: ' .. totalDifficulty)

    --if #monsters > 0 then
    --    -- Iterate through the existing items in the room
    --    for _, item in pairs(self.room.items) do
    --        -- Give the item to a random monster
    --        monsters[math.random(1, #monsters)]:pick_up(item)
    --    end
    --end

    self:position_objects(monsters)

    self.addedMonsters = true

    -- Flag that this step was not already complete; we had to do work
    return false
end

function RoomFiller:add_turrets()
    if self.addedTurrets then
        -- Flag that this step was already completed
        return true
    end

    -- The minimum number of turrets is always 3
    local min = 3

    -- Set the maximum number of turrets in a row, depending on the room's size
    -- and difficulty
    local max = math.random(0, #self.room.bricks * .02 *
                            (self.room.difficulty * .1))
    --print('max turrets:', max)

    if max >= min then
        local turretPositions, dir = self:find_turret_positions(min, max)
        if turretPositions then
            for _, pos in pairs(turretPositions) do
                self.room:add_object(Turret(pos, dir))
            end
        end
    end

    self.addedTurrets = true

    -- Flag that the turrets weren't already generated
    return false
end

function RoomFiller:find_turret_positions(min, max)
    -- This is the table of turret positions we will return
    local positions = {}

    -- Make a copy of the room's brick table
    local bricks = copy_table(self.room.bricks)

    while #bricks > 0 do
        local srcPos, shootableDirs
        while #bricks > 0 do
            -- Pick a random brick's position as the starting position
            local brickIndex = math.random(1, #bricks)

            srcPos = bricks[brickIndex]:get_position()

            shootableDirs = shootable_directions(srcPos, self.room.freeTiles)

            if #shootableDirs == 0 or #shootableDirs > 3 then
                -- Remove this starting position from consideration
                table.remove(bricks, brickIndex)
            else
                -- Use this starting position
                break
            end
        end

        -- Iterate through the directions in which there is room to shoot
        for _, shootDir in pairs(shootableDirs) do
            -- Reset the positions table to only the source position
            positions = {srcPos}

            -- Iterate through the directions in which we should look for
            -- neighboring bricks
            for _, dir in pairs(perpendicular_directions(shootDir)) do
                -- Search out from the source brick
                local pos = srcPos
                while true do
                    -- Move to the next tile in this direction
                    pos = add_direction(pos, dir)

                    -- If there is a brick here
                    local tile = self.room.tileCache:get_tile(pos)
                    if tile:contains_class(Brick) then
                        -- If one of the shootable directions from this tile
                        -- is the same as the source brick's shooting direction
                        if value_in_table(shootDir, shootable_directions(pos,
                                                    self.room.freeTiles)) then
                            -- Add a turret position here
                            table.insert(positions, pos)

                            -- If we have reached our maximum number of turret
                            -- positions in a row
                            if #positions == max then
                                return positions, shootDir
                            end
                        else
                            -- Stop searching for neighboring bricks in this
                            -- direction
                            break
                        end
                    else
                        -- Stop searching for neighboring bricks in this
                        -- direction
                        break
                    end
                end
            end

            -- If we found a long enough row of positions
            if #positions >= min then
                return positions, shootDir
            else
                -- Remove all the positions from future consideration
                for i,p in pairs(positions) do
                    for j,b in pairs(bricks) do
                        if tiles_overlap(p, b) then
                            table.remove(bricks, j)
                            break
                        end
                    end
                end
            end
        end
    end
end

function RoomFiller:add_required_objects()
    if not self.room.requiredObjects or #self.room.requiredObjects == 0 then
        -- Flag that the required objects have already been added (or there
        -- never were any)
        return true
    end

    -- For objects that already have positions, just add them to the room
    local unpositionedObjects = {}
    for _, obj in pairs(self.room.requiredObjects) do
        local pos = obj:get_position()

        if pos.x and pos.y  then
            self.room:add_object(obj)

            -- Remove the object's position from future use
            self:use_tile(pos)
        else
            table.insert(unpositionedObjects, obj)
        end
    end

    -- Give positions to objects that need positions
    self:position_objects(unpositionedObjects)
    self.room.requiredObjects = nil

    -- Flag that the required objects were not already added before now
    return false
end

function RoomFiller:get_item_types()
    -- Return the possible item types that are appropriate for this
    -- room
    local itemTypes = {}
    if self.room.isSecret then
        itemTypes = {'arrow', 'elixir', 'shinything', 'potion'}

        if self.room.difficulty < MONSTER_DIFFICULTY['archer'] then
            table.insert(itemTypes, 'bow')
        end
    else
        itemTypes = {'arrow', 'elixir'}

        if self.room.difficulty >= 33 then
            table.insert(itemTypes, 'potion')
        end
    end

    return itemTypes
end

function RoomFiller:get_max_monsters()
end

function RoomFiller:position_objects(objects)
    local ok

    for _, o in pairs(objects) do
        while #self.itemTiles > 0 do
            -- Pick a random free tile
            local tileIndex = math.random(1, #self.itemTiles)
            local position = self.itemTiles[tileIndex]

            -- Remove this tile from future consideration
            ok = self:use_tile(position)

            -- If this position was available
            if ok then
                -- Set the object's position to that of our chosen tile
                o:set_position(position)

                -- Add this object to the room
                self.room:add_object(o)
                break
            end
        end

        if DEBUG and #self.itemTiles == 0 then
            print('no more places to position object:', o)
        end
    end
end

function RoomFiller:use_tile(tile)
    -- Remove this tile from future use by items
    for j, ft in pairs(self.itemTiles) do
        if tiles_overlap(tile, ft) then
            table.remove(self.itemTiles, j)

            -- Signal that the tile was available
            return true
        end
    end

    -- Signal that the tile was not available
    return false
end
