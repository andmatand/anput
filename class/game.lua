require('class.gamesummary')
require('class.map')
require('class.mapdisplay')
require('class.player')
require('util.tables')
require('util.tile')

-- A Game handles a collection of rooms
Game = class('Game')

function Game:init(wrapper)
    self.wrapper = wrapper

    self.isPaused = false
    self.time = 0
    self.tutorial = {playerMoved = false,
                     playerShot = false}

    -- Create the outside "room"
    self.outside = Room({game = self, index = -1})
    self.outside.isBuilt = true
    self.outside.isGenerated = true
    self.numOutsideVisits = 0
end

function Game:add_time(seconds)
    if not self.isPaused then
        self.time = self.time + seconds
    end
end

function Game:draw()
    if self.isPaused then
        SCALE_X = SCALE_X * 2
        SCALE_Y = SCALE_Y * 2

        local tx = -upscale_x(self.player.position.x + .5) +
                   upscale_x(ROOM_W / 4)
        local ty = -upscale_y(self.player.position.y + .5) +
                   upscale_y(ROOM_H / 4)

        love.graphics.push()
        love.graphics.translate(tx, ty)
    end

    self.currentRoom:draw()

    if self.isPaused then
        love.graphics.pop()
        SCALE_X = SCALE_X / 2
        SCALE_Y = SCALE_Y / 2

        self.mapDisplay:draw(self.currentRoom)
    end

    self:draw_metadata()
end

function Game:draw_metadata()
    love.graphics.setColor(255, 255, 255)

    if self.player.isDead then
        if not self.summary then
            self.summary = GameSummary(self)
        end

        self.summary:draw()
    end

    self.player.statusBar:draw()
end

function Game:generate()
    -- Generate a new map
    self.map = Map({game = self})
    self.rooms = self.map:generate()
    roomGenTimer = love.timer.getTime()
    self.generatedAllRooms = false

    -- Create the map display
    self.mapDisplay = MapDisplay(self.map)

    -- Create a player
    self.player = Player(self)

    -- Switch to the first room
    self:move_player_to_start()

    self:position_sword()
end

function Game:get_adjacent_rooms()
    local rooms = {}

    for _, e in pairs(self.currentRoom.exits) do
        table.insert(rooms, e.targetRoom)
    end

    return rooms
end

function Game:holdable_key_input()
    -- Check if the walk keys are down
    for _, key in pairs(self.wrapper.holdableKeys) do
        if key.state > 0 then
            self.player:key_held(key.keyValue)
        end
    end
end

function Game:is_paused()
    return (self.isPaused == true)
end

function Game:key_pressed(key)
    if self.player.isDead then
        if key == KEYS.CONTEXT then
            self.wrapper:restart()
        end
    end

    self.player:key_pressed(key)
end

function Game:key_released(key)
    if (self.player.attackedDir == 1 and key == KEYS.WALK.NORTH) or
       (self.player.attackedDir == 2 and key == KEYS.WALK.EAST) or
       (self.player.attackedDir == 3 and key == KEYS.WALK.SOUTH) or
       (self.player.attackedDir == 4 and key == KEYS.WALK.WEST) then
        self.player.attackedDir = nil
    end
end

function Game:move_player_to_start()
    local room = self.rooms[1]

    self:switch_to_room(room)

    self.player:move_to_room(room)

    -- Put the player at the temple exit
    local templeExit = room:find_exit({targetRoom = self.outside})
    self.player:set_position(templeExit:get_doorway())

    -- Face the player toward the room's midpoint (left/right only)
    if room.midPoint.x < self.player.position.x then
        self.player.dir = 4
    else
        self.player.dir = 2
    end
end

function Game:pause()
    if not self.isPaused then
        self.isPaused = true
    end
end

function Game:position_sword()
    -- Put the sword midway along the path the player will need to take to
    -- reach the exit to the second room
    local firstRoom = self.rooms[1]
    local exitToSecondRoom = firstRoom:find_exit({targetRoom = self.rooms[2]})

    local pf = PathFinder(self.player:get_position(),
                          exitToSecondRoom:get_doorway(),
                          firstRoom.bricks)
    local path = pf:plot()
    local swordPosition = path[math.floor(#path / 2)]
    for _, item in pairs(firstRoom.items) do
        if item.itemType == 'sword' then
            item:set_position(swordPosition)
            break
        end
    end
end

function Game:set_demo_mode(tf)
    self.demoMode = tf

    if self.demoMode then
        if not self.player.ai then
            self.player.tag = true
            self.player.ai = AI(self.player)
            self.player.ai.choiceTimer.delay = .1
            self.player.ai.level.aim = {dist = 20, prob = 10, delay = .05}
            self.player.ai.level.attack = {dist = 20, prob = 10, delay = .1}
            self.player.ai.level.avoid = {prob = 10, delay = 0}
            self.player.ai.level.chase = {dist = 20, prob = 9, delay = .05}
            self.player.ai.level.dodge = {dist = 20, prob = 10, delay = .05}
            self.player.ai.level.explore = {dist = 20, prob = 9, delay = .05}
            self.player.ai.level.flee = {dist = 20, prob = 10, delay = .05}
            self.player.ai.level.heal = {dist = 20, prob = 10, delay = .05}
            self.player.ai.level.loot = {dist = 20, prob = 9, delay = .05}

            print('gave AI to player')
        end
    else
        self.player.ai = nil
    end
end

function Game:show_tutorial_messages()
    -- If the player has not moved for the first three seconds of the game
    if not self.tutorial.playerMoved and self.time >= 3 then
        -- Show a contextual help message
        self.player.statusBar:show_context_message({'w', 'a', 's', 'd'},
                                                   'MOVE')
    end
    if self.player.stepped then
        self.tutorial.playerMoved = true
    end

    -- If the player has a shootable weapon equipped
    if not self.tutorial.playerShot and self.player.armory.currentWeapon and
       self.player.armory.currentWeapon.canShoot then
        self.player.statusBar:show_context_message({'up', 'down', 'left',
                                                    'right'}, 'SHOOT')
    end
    if self.player.shot then
        self.tutorial.playerShot = true
    end
end

function Game:spawn_more_monsters()
    if not self.spawnTimer or self.time >= self.spawnTimer + 10 then
        self.spawnTimer = self.time
    else
        return
    end

    -- Find a random room that has less than its target total monster
    -- difficulty
    local rooms = copy_table(self.rooms)
    while #rooms > 0 do
        local index = love.math.random(1, #rooms)
        local room = rooms[index]

        local ok = false
        local totalDifficulty

        -- If this is a room which can have monsters added to it
        if room.isGenerated and not room.isSecret and not room.roadblock and
           room.index > 1 and room ~= self.currentRoom then
            ok = true

            -- Check if the total monster difficulty is lower than the room's
            -- difficulty
            totalDifficulty = 0
            for _, sprite in pairs(room.sprites) do
                if instanceOf(Monster, sprite) then
                    totalDifficulty = totalDifficulty + sprite.difficulty

                    -- If the total monster difficulty is already at its
                    -- maximum
                    if totalDifficulty >= room.difficulty then
                        -- There is no more room for new monsters
                        ok = false
                        break
                    end
                end
            end
        end

        -- If it's okay to add a new monster to the room
        if ok then
            if DEBUG then
                print('trying to spawn a monster in room ' .. room.index)
            end

            local possibleMonsterTypes = {}
            for monsterType, difficulty in pairs(MONSTER_DIFFICULTY) do
                if difficulty and
                   difficulty <= room.difficulty - totalDifficulty then
                    table.insert(possibleMonsterTypes, monsterType)
                end
            end

            if #possibleMonsterTypes > 0 then
                local index = love.math.random(1, #possibleMonsterTypes)
                local newMonsterType = possibleMonsterTypes[index]
                local newMonster = Monster(self, newMonsterType)
                local position = room:get_free_tile()

                if position then
                    if DEBUG then
                        print('spawning a ' .. newMonsterType .. ' in room ' ..
                              room.index)
                    end

                    newMonster:set_position(room:get_free_tile())
                    room:add_object(newMonster)

                    if love.math.random(1, 3) == 1 then
                        -- Choose a random item type
                        local roomFiller = RoomFiller(room)
                        local itemTypes = roomFiller:get_item_types()
                        roomFiller:give_random_items_to_monster(newMonster,
                                                                itemTypes)
                    end

                    return
                end
            end
        end

        table.remove(rooms, index)
    end
end

function Game:switch_to_room(room)
    --if DEBUG then
        print('switching to room ' .. room.index)
        print('  PRNG seed: ' .. room.randomSeed)
        print('  distance from start: ' .. room.distanceFromStart)
        print('  difficulty: ' .. room.difficulty)
    --end

    self.previousRoom = self.currentRoom

    -- If there was a previous room
    --if self.previousRoom then
        -- Clear previous room's FOV cache to save memory
        --self.previousRoom.fovCache = {}
    --end

    -- Set the new room as the current room
    self.currentRoom = room
    self.currentRoom.isVisited = true

    -- Make sure the room has been completely generated
    if not self.currentRoom.isGenerated then
        self.currentRoom:generate_all()
    end

    -- Force the new current room to update its FOV
    self.currentRoom.fov = nil

    -- Clear any dead objects
    self.currentRoom:sweep()

    if DEBUG then
        if #room.switches > 0 then
            print('  switches: ')
            for i, s in pairs(room.switches) do
                print('    switch ' .. i)
                print('      position:' , s.position.x, s.position.y)
                print('      door position:', s.door.position.x,
                s.door.position.y)
                print('      door room:', s.door.room.index)
            end
        end
    end
end

function Game:unpause()
    if self.isPaused then
        self.isPaused = false
    end
end

function Game:update(dt)
    if not self.playedTheme then
        sounds.theme:play()
        self.playedTheme = true
    end

    self.player.statusBar:update()

    if self.isPaused then
        self.mapDisplay:update()
        return
    end

    if self.summary then
        self.summary:update()
    end

    self:holdable_key_input()
    self:show_tutorial_messages()

    self:spawn_more_monsters()

    -- Update the current room
    self.currentRoom:update()

    -- Update the adjacent rooms
    for _, room in pairs(self:get_adjacent_rooms()) do
        if room ~= self.outside then
            room:update()
        end
    end

    -- If the player entered a different room
    if self.player.room and self.player.room ~= self.currentRoom then
        -- If the player is outside the temple
        if self.player.room == self.outside then
            -- Add to the total number of times the player has walked outside
            self.numOutsideVisits = self.numOutsideVisits + 1

            -- Mark the game as finished (for now)
            self.finished = true
        else
            -- Switch the game view to the player's current room
            self:switch_to_room(self.player.room)
        end
    end
end
