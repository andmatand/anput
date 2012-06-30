require('class/item')
require('class/monster')
require('class/turret')
require('util/tile')
require('util/tables')

-- A RoomFiller fills a room with monsters, items
RoomFiller = class('RoomFiller')

function RoomFiller:init(room)
    self.room = room

    -- Make a copy of the room's free tiles for manipulation
    self.freeTiles = copy_table(self.room.freeTiles)

    -- Remove doorways from freeTiles
    for _, e in pairs(self.room.exits) do
        local dw = e:get_doorway()
        for i, t in pairs(self.freeTiles) do
            -- If this free tile is a doorway
            if tiles_overlap(t, dw) then
                -- Remove it from consideration
                table.remove(self.freeTiles, i)
                break
            end
        end
    end

    -- Remove midPoint from freeTiles
    for i, t in pairs(self.freeTiles) do
        if tiles_overlap(t, self.room.midPoint) then
            table.remove(self.freeTiles, i)
            break
        end
    end
end

function RoomFiller:fill_next_step()
    if self:add_required_objects() then
        if self:add_internal_bricks() then
            if self:add_turrets() then
                if self:add_monsters() then
                    -- Flag that room is done being filled
                    return true
                end
            end
        end
    end

    -- Flag that room is not yet done being filled
    return false
end

function RoomFiller:add_monsters()
    local max = #self.room.freeTiles * .04

    if self.addedMonsters or self.room.isSecret then
        -- Flag that this step was already completed
        return true
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
        for mt, diff in ipairs(MONSTER_DIFFICULTY) do
            if diff + totalDifficulty > self.room.difficulty then
                break
            end
            hardest = diff
            monsterType = mt
        end

        totalDifficulty = totalDifficulty + hardest
        table.insert(monsters, Monster({}, monsterType))
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

    -- Give items to the monsters
    for _, m in pairs(monsters) do
        if math.random(m.difficulty, 100) >= 25 then
            -- Choose a random item type
            local itemType = math.random(1, 2)

            local newItem = Item(itemType)

            -- Pretend the monster picked it up
            m:pick_up(newItem)
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

            shootableDirs = shootable_directions(srcPos,
                                                 self.room.freeTiles)

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
    for _ = 1, math.random(0, #self.room.freeTiles * .02) do
        table.insert(someBricks, Brick({}))
    end

    -- Place bricks in room
    self:position_objects(someBricks)

    -- Remove the bricks' positions from the room's freeTiles
    for _, b in pairs(someBricks) do
        for i, ft in pairs(self.room.freeTiles) do
            if tiles_overlap(b, ft) then
                table.remove(self.room.freeTiles, i)
                break
            end
        end
    end

    self.addedInternalBricks = true

    -- Flag that internal bricks were not already added before now
    return false
end

function RoomFiller:position_objects(objects)
    local ok

    for _, o in pairs(objects) do
        while #self.freeTiles > 0 do
            -- Pick a random free tile
            local tileIndex = math.random(1, #self.freeTiles)
            local position = self.freeTiles[tileIndex]

            -- Remove this tile from future consideration
            table.remove(self.freeTiles, tileIndex)

            -- If this object cannot overlap with other objects
            if o.isCorporeal then
                ok = false

                -- Find the neighbor tiles
                local neighbors = find_neighbor_tiles(position,
                                                      self.room.bricks)

                -- Make sure there are at least 5 unoccupied
                -- clockwise-consecuitive neighbor tiles in a row
                local numInARow = 0
                for _, n in ipairs(neighbors) do
                    if n.occupied then
                        numInARow = 0
                    else
                        numInARow = numInARow + 1
                    end

                    if numInARow == 5 then
                        ok = true
                        break
                    end
                end
            else
                ok = true
            end

            -- If this position is available
            if ok then
                -- Set the object's position to that of our chosen tile
                o:set_position(position)

                -- Add this object to the room
                self.room:add_object(o)
                break
            end
        end

        if #self.freeTiles == 0 then
            print('no more places to position object:', o)
        end
    end
end
