require('class.hieroglyph')
require('class.item')
require('class.monster')
require('class.turret')
require('util.tile')
require('util.tables')

-- A RoomFiller fills a room with monsters, items
RoomFiller = class('RoomFiller')

function RoomFiller:init(room)
    self.room = room

    -- Make a table of tiles in which (walkable) items may be placed
    self.itemTiles = copy_table(self.room.freeTiles)
    
    -- Make a table of tiles in which (non-walkable) obstacles may be placed
    self.obstacleTiles = copy_table(self.room.freeTiles)

    -- Remove doorway tiles from future use
    for _, e in pairs(self.room.exits) do
        local dw = e:get_doorway()
        self:use_tile(dw)
    end

    -- Remove the room's midPoint from future use
    self:use_tile(self.room.midPoint)
end

function RoomFiller:fill_next_step()
    -- If this road is supposed to contain a roadblock
    if self.room.roadblock then
        if self:add_roadblock() then
            return true
        end
    else
        if self:add_required_objects() then
            if self:add_internal_bricks() then
                if self:add_hieroglyphs() then
                    if self:add_turrets() then
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

function RoomFiller:add_roadblock()
    if self.addedRoadblock then
        return true
    end

    --if self.room.roadblock == 'lake' then
    --    -- Create a lake from the water tiles
    --    local lake = Lake(self.room.zoneTiles)

    --    -- Add the lake to the room
    --    self.room:add_object(lake)
    --end

    self.addedRoadblock = true
    return false
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
            for _, ft in pairs(self.room.freeTiles) do
                if ft.x == b.x and ft.y == b.y + 1 then
                    ok = true
                    break
                end
            end
        else
            ok = true
        end

        if ok then
            table.insert(goodBricks, b)
        end
    end

    -- Find a long enough row of bricks
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
                elseif #bricksInARow < #letters then
                    removeBricks = true
                end
            end

            -- If we found enough bricks for all the letters
            if #bricksInARow == #letters then
                -- Create the letters over the bricks
                for i, b in ipairs(bricksInARow) do
                    table.insert(self.room.hieroglyphs,
                                 Hieroglyph(b:get_position(), letters[i]))
                end
                removeBricks = true

                -- Don't add any more hieroglyphs
                return true
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
    if self.addedItems then
        return true
    end

    local addedElixir = false

    local itemTypes = {'elixir'}
    if self.room.difficulty >= MONSTER_DIFFICULTY['archer'] / 2 then
        table.insert(itemTypes, 'arrow')
    end
    if self.room.difficulty >= 50 then
        table.insert(itemTypes, 'potion')
    end

    -- If this is a secret room
    if self.room.isSecret then
        -- Add some goodies
        local numGoodies = math.random(3, 8)
        local goodies = {}
        local itemTypes = {'arrow', 'elixir', 'shinything', 'potion'}

        if self.room.difficulty < MONSTER_DIFFICULTY['archer'] then
            table.insert(itemTypes, 'bow')
        end

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
                -- Choose a random item type
                local itemType = itemTypes[math.random(1, #itemTypes)]

                if itemType == 'elixir' then
                    -- Do not allow adding any more elixirs to this room
                    remove_value_from_table('elixir', itemTypes)
                end

                local newItem = Item(itemType)

                -- Pretend the monster picked it up
                m:pick_up(newItem)
            end
        end
    end

    self.addedItems = true
    return false
end

function RoomFiller:add_monsters()
    local max = #self.room.freeTiles * .04

    if self.addedMonsters then
        -- Flag that this step was already completed
        return true
    end

    if self.room.isSecret then
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
    -- order to meet room difficulty level, without exceding the room's maximum
    -- occupancy
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

    if #monsters > 0 then
        -- Iterate through the existing items in the room
        for _, item in pairs(self.room.items) do
            -- Give the item to a random monster
            monsters[math.random(1, #monsters)]:pick_up(item)
        end
    end

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
            -- neighboring /ricks
            for _, dir in pairs(perpendicular_directions(shootDir)) do
                -- Search out from the source brick
                local pos = srcPos
                while true do
                    -- Move to the next tile in this direction
                    pos = add_direction(pos, dir)

                    -- If there is a brick here
                    if tile_in_table(pos, bricks) then
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

function RoomFiller:add_internal_bricks()
    if self.addedInternalBricks then
        -- Flag that internal have already already been added
        return true
    end

    local someBricks = {}
    for _ = 1, math.random(0, #self.room.freeTiles * .07) do
        table.insert(someBricks, Brick({}))
    end

    local seedBricks = copy_table(self.room.bricks)

    local previoiusPosition, position, ok
    for _, brick in pairs(someBricks) do
        ok = false

        -- If there was no previous brick
        if not previoiusPosition then
            -- Pick a random brick in the room
            while #seedBricks > 0 do
                local index = math.random(1, #seedBricks)
                local pos = seedBricks[index]

                if consecutive_free_neighbors(pos, self.room.bricks, 5) then
                    previoiusPosition = pos
                    break
                else
                    table.remove(seedBricks, index)
                end
            end
        end
        
        -- If we have the position of a previous brick
        if previoiusPosition then
            -- Find a position adjacent to the previous position
            local neighbors = adjacent_tiles(previoiusPosition)
            while #neighbors > 0 do
                local index = math.random(1, #neighbors)
                local pos = neighbors[index]

                -- If a brick can fit here
                if self:use_obstacle_tile(pos) then
                    position = pos
                    ok = true
                    break
                else
                    -- Remove this position from consideration
                    table.remove(neighbors, index)
                end
            end
        else
            -- Pick a random free position in the room
            while #self.obstacleTiles > 0 do
                local index = math.random(1, #self.obstacleTiles)
                local pos = self.obstacleTiles[index]
                
                -- If a brick can fit here
                if self:use_obstacle_tile(pos) then
                    position = pos
                    ok = true
                    break
                end
            end
        end

        if ok then
            brick:set_position(position)
            self.room:add_object(brick)

            previoiusPosition = position
        else
            previoiusPosition = nil
        end
    end

    -- Place bricks in room
    --self:position_objects(someBricks)

    self.addedInternalBricks = true

    -- Flag that internal bricks were not already added before now
    return false
end

function RoomFiller:position_objects(objects)
    local ok

    for _, o in pairs(objects) do
        while #self.itemTiles > 0 do
            -- Pick a random free tile
            local tileIndex = math.random(1, #self.itemTiles)
            local position = self.itemTiles[tileIndex]

            -- Remove this tile from future consideration
            if o.isMovable then
                ok = self:use_tile(position)
            else
                ok = self:use_obstacle_tile(position)
            end

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

function RoomFiller:use_obstacle_tile(tile)
    local tileIsAvailable = false

    for i, t in pairs(self.obstacleTiles) do
        if tiles_overlap(tile, t) then
            tileIsAvailable = true

            -- Remove the tile from future use by obstacles
            table.remove(self.obstacleTiles, i)

            break
        end
    end

    -- If this tile is still available
    if tileIsAvailable then
        local ok = false

        -- If this tile has 5 consecutive free adjacent tiles
        if consecutive_free_neighbors(tile, self.room:get_obstacles(), 5) then
            ok = true
        end

        if ok then
            -- Make sure the position is not blocking a doorway
            for _, e in pairs(self.room.exits) do
                if tiles_touching(tile, e:get_doorway()) then
                    ok = false
                    break
                end
            end
        end

        if ok then
            -- Remove the tile from the room's freeTiles
            for i, t in pairs(self.room.freeTiles) do
                if tiles_overlap(tile, t) then
                    table.remove(self.room.freeTiles, i)
                    break
                end
            end

            return true
        end
    end

    return false
end

function RoomFiller:use_tile(tile)
    -- Ensure the tile is still available
    for i, t in pairs(self.obstacleTiles) do
        if tiles_overlap(tile, t) then
            -- Remove this tile from future use by obstacles
            table.remove(self.obstacleTiles, i)

            -- Remove this tile from future use by items
            for j, ft in pairs(self.itemTiles) do
                if tiles_overlap(tile, ft) then
                    table.remove(self.itemTiles, j)
                    break
                end
            end

            -- Signal that the tile was available
            return true
        end
    end

    -- Signal that the tile was not available
    return false
end
