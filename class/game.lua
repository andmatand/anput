require('class.inventorymenu')
require('class.map')
require('class.player')
require('class.statusbar')
require('util.tables')
require('util.tile')

-- A Game handles a collection of rooms
Game = class('Game')

function Game:init(wrapper)
    self.wrapper = wrapper

    self.paused = false
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
    if not self.paused then
        self.time = self.time + seconds
    end
end

function Game:draw()
    if self.paused then
        SCALE_X = SCALE_X * 2
        SCALE_Y = SCALE_Y * 2

        local tx = -upscale_x(self.player.position.x + .5) +
                   upscale_x(ROOM_W / 4)
        local ty = -upscale_x(self.player.position.y + .5) +
                   upscale_y(ROOM_H / 4)

        love.graphics.push()
        love.graphics.translate(tx, ty)
    end

    self.currentRoom:draw()

    if self.paused then
        love.graphics.pop()
        SCALE_X = SCALE_X / 2
        SCALE_Y = SCALE_Y / 2
    end

    self:draw_metadata()

    if self.paused then
        -- Dither out the screen
        --for x = 0, BASE_SCREEN_W * SCALE_X, SCALE_X * 2 do
        --    love.graphics.setColor(BLACK)
        --    love.graphics.rectangle('fill',
        --                            x, 0,
        --                            SCALE_X,
        --                            (BASE_SCREEN_H * SCALE_Y) - upscale_y(1))
        --end

        -- Dim the screen
        --love.graphics.setColor(0, 0, 0, 128)
        --love.graphics.rectangle('fill', 0, 0,
        --                        BASE_SCREEN_W * SCALE_X,
        --                        (BASE_SCREEN_H * SCALE_Y) - upscale_y(1))


        local offset = math.floor(self.menuOffset / upscale_x(1))
        offset = offset * upscale_x(1)

        love.graphics.push()
        love.graphics.translate(-offset, 0)
        self.inventoryMenu:draw()
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(offset, 0)
        self.map:draw(self.currentRoom)
        love.graphics.pop()
    end
end

function Game:draw_metadata()
    love.graphics.setColor(255, 255, 255)

    self.statusBar:draw()

    if self.player.isDead then
        local visitedRooms = 0
        for _, r in pairs(self.rooms) do
            if r.visited then
                visitedRooms = visitedRooms + 1
            end
        end

        local x = 1
        local y = 1
        local msg = "YOU WERE KILLED BY "
        cga_print(msg, x, y)
        x = x + msg:len()
        cga_print(" ", x, y)
        self.player.log.wasKilledBy:draw({x = upscale_x(x), y = upscale_y(y)})

        if #self.player.log:get_kills() > 0 then
            x = 1
            y = y + 2
            local msg = "YOU KILLED "
            cga_print(msg, x, y)

            x = x + msg:len()
            for _, k in pairs(self.player.log:get_kills()) do
                k.flashTimer = 0

                cga_print(" ", x, y)
                print('drawing: ', k)
                k:draw({x = upscale_x(x), y = upscale_y(y)})

                x = x + 1
                if x == GRID_W - 1 then
                    x = 1
                    y = y + 1
                end
            end
        end
    end
end

function Game:generate()
    self.randomSeed = os.time() + math.random(0, 1000)
    --self.randomSeed = 1358040137
    math.randomseed(self.randomSeed)
    print('\nrandom seed for game: ' .. self.randomSeed)

    -- Generate a new map
    self.map = Map({game = self})
    self.rooms = self.map:generate()
    roomGenTimer = love.timer.getTime()
    self.generatedAllRooms = false

    -- Create a player
    self.player = Player()

    -- Switch to the first room
    self:move_player_to_start()

    -- Put the sword close to the entrance of the first room
    local swordPos
    local freeTiles = copy_table(self.currentRoom.freeTiles)
    while #freeTiles > 0 do
        local index = math.random(1, #freeTiles)
        local dist = manhattan_distance(freeTiles[index],
                                        self.player:get_position())
        if dist > 1 and dist <= 7 then
            swordPos = freeTiles[index]
            break
        else
            table.remove(freeTiles, index)
        end
    end
    for _, item in pairs(self.currentRoom.items) do
        if item.itemType == 'sword' then
            item:set_position(swordPos)
            break
        end
    end

    -- Create a status bar
    self.statusBar = StatusBar(self.player, self)

    -- Create an inventory menu
    self.inventoryMenu = InventoryMenu(self.player)
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

function Game:key_pressed(key)
    if self.player.isDead then
        if key == KEYS.CONTEXT then
            self.wrapper:restart()
        end
    end

    -- Toggle pause
    if key == KEYS.PAUSE then
        if self.paused then
            self:unpause()
        else
            self:pause()
        end
    end

    -- Toggle inventory menu
    if key == KEYS.INVENTORY or (self.paused and self.menuState == 'map' and
                                 key == KEYS.SWITCH_MENU) then
        if self.paused and self.menuState == 'inventory' then
            self:unpause()
        else
            if not self.paused then
                self:pause()
            else
                sounds.menuSelect:play()
            end

            self.menuState = 'inventory'
        end

    -- Toggle map
    elseif key == KEYS.MAP or (self.paused and self.menuState == 'inventory' and
                               key == KEYS.SWITCH_MENU) then
        if self.paused and self.menuState == 'map' then
            self:unpause()
        else
            if not self.paused then
                self:pause()
            else
                sounds.menuSelect:play()
            end
        end

        self.menuState = 'map'
    end

    -- If the game is paused
    if self.paused then
        -- Route input to inventory menu
        if self.inventoryMenu:key_pressed(key) then
            -- InventoryMenu:keypressed() evaluates to true when the user
            -- exits the menu
            self.paused = false
        end
    end

    self.player:key_pressed(key)
end

function Game:key_released(key)
    if self.paused then
        -- Route input to the inventory menu
        self.inventoryMenu:key_released(key)
    end

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
    local templeExit = room:get_exit({targetRoom = self.outside})
    self.player:set_position(templeExit:get_doorway())

    -- Face the player toward the room's midpoint (left/right only)
    if room.midPoint.x < self.player.position.x then
        self.player.dir = 4
    else
        self.player.dir = 2
    end
end

function Game:pause()
    if not self.paused then
        sounds.pause:play()

        --self.menuOffset = upscale_x(9)
        self.menuOffset = 0

        -- Refresh the inventory menu
        self.inventoryMenu:refresh_items()

        self.paused = true
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
        self.statusBar:show_context_message({'w', 'a', 's', 'd'}, 'MOVE')
    end
    if self.player.stepped then
        self.tutorial.playerMoved = true
    end

    -- If the player has a shootable weapon equipped
    if not self.tutorial.playerShot and self.player.armory.currentWeapon and
       self.player.armory.currentWeapon.canShoot then
        self.statusBar:show_context_message({'up', 'down', 'left', 'right'},
                                            'SHOOT')
    end
    if self.player.shot then
        self.tutorial.playerShot = true
    end
end

function Game:switch_to_room(room)
    --if DEBUG then
        print('switching to room ' .. room.index)
        print('  random seed: ' .. room.randomSeed)
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
    self.currentRoom.visited = true

    -- Make sure the room has been completely generated
    if not self.currentRoom.isGenerated then
        self.currentRoom:generate_all()
    end

    -- Force the new current room to update its FOV
    self.currentRoom.fov = nil

    -- Clear any dead objects
    self.currentRoom:sweep()

    --if DEBUG then
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
    --end
end

function Game:unpause()
    if self.paused then
        self.paused = false
    end
end

function Game:update(dt)
    if not self.playedTheme then
        --sounds.theme:play()
        self.playedTheme = true
    end

    if self.player.isDead then
        if not self.playerDeadTimer then
            self.playerDeadTimer = self.time
        end

        if self.time >= self.playerDeadTimer + 3 then
            self.statusBar:show_context_message({'enter'}, 'NEW GAME')
        end
    end

    self.statusBar:update()

    if self.paused then
        if self.menuOffset > 0 then
            self.menuOffset = self.menuOffset / 4
            --self.menuOffset = self.menuOffset - upscale_x(3)
        end

        self.inventoryMenu:update()
        self.map:update()
        return
    end

    self:holdable_key_input()
    self:show_tutorial_messages()

    -- Update the current room
    self.currentRoom:update()

    -- Update the adjacent rooms
    for _, room in pairs(self:get_adjacent_rooms()) do
        if room.isGenerated then
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

    -- Switch rooms when player is on an exit
    --for _, e in pairs(self.currentRoom.exits) do
    --    if tiles_overlap(self.player.position, e) then
    --        break
    --    end
    --end
end
