require('class/item')
require('class/monster')
require('class/turret')

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

    if self.addedMonsters then
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
        for mt, diff in ipairs(Monster.static.difficulties) do
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


function RoomFiller:add_objects(num, fTest, fNew, freeTiles)
    args = {}
    for i = 1, num do
        for tries = 1, 5 do
            local position = freeTiles[math.random(1, #freeTiles)]

            local ok = true
            if fTest == nil then
                -- Default test function: Don't place in occupied tile
                if not self.room:tile_walkable(position) then
                    ok = false
                end
            else
                testResult = fTest(self, position)
                ok = testResult.ok
                for k,v in pairs(testResult) do
                    if k ~= 'ok' then
                        args[k] = v
                    end
                end
            end

            if ok then
                args.position = position
                self.room:add_object(fNew(args))
                break
            end
        end
    end
end

function RoomFiller:add_turrets()
    if self.addedTurrets then
        -- Flag that this step was already completed
        return true
    end

    local numTurrets = math.random(0, #self.room.bricks * .03)
    fTest =
        function(roomFiller, pos)
            -- Find a direction in which we can fire
            dirs = {1, 2, 3, 4}
            while #dirs > 0 do
                index = math.random(1, #dirs)
                dir = dirs[index]
                pos2 = {x = pos.x, y = pos.y}

                -- Find the coordinates of three spaces ahead
                if dir == 1 then
                    pos2.y = pos2.y - 3 -- North
                elseif dir == 2 then
                    pos2.x = pos2.x + 3 -- East
                elseif dir == 3 then
                    pos2.y = pos2.y + 3 -- South
                elseif dir == 4 then
                    pos2.x = pos2.x - 3 -- West
                end

                -- Check if there is a line of sight between these tiles
                if roomFiller.room:line_of_sight(pos, pos2) then
                    return {dir = dir, ok = true}
                else
                    table.remove(dirs, index)
                end
            end
            return {ok = false}
        end
    fNew =
        function(pos)
            return Turret(args.position, args.dir, 5 * math.random(1, 10))
        end
    self:add_objects(numTurrets, fTest, fNew, self.room.bricks)

    self.addedTurrets = true

    return false
end

function RoomFiller:add_required_objects()
    if not self.room.requiredObjects or #self.room.requiredObjects == 0 then
        -- Flag that the required objects have already been added (or there
        -- never were any)
        return true
    end

    -- Give positions to objects required to be in this room
    self:position_objects(self.room.requiredObjects)
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
    self:position_objects(someBricks)

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
