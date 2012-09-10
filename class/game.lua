require('class.inventorymenu')
require('class.map')
require('class.player')
require('class.statusbar')
require('util.tables')
require('util.tile')

--local DEBUG = true

-- A Game handles a collection of rooms
Game = class('Game')

function Game:init()
    self.menuState = 'inventory'
    self.paused = false
    self.time = 0
    self.playerMoved = false

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
    self.currentRoom:draw()

    if DEBUG then
        -- Show tiles added to make room for required room objects
        --if #self.currentRoom.debugTiles > 0 then
        --    for _, t in pairs(self.currentRoom.debugTiles) do
        --        love.graphics.setColor(0, 255, 0, 100)
        --        love.graphics.rectangle('fill', upscale_x(t.x), upscale_x(t.y),
        --                                upscale_x(1), upscale_y(1))
        --    end
        --end

    end

    self:draw_metadata()

    if self.paused then
        if self.menuState == 'inventory' then
            self.inventoryMenu:draw()
        elseif self.menuState == 'map' then
            self.map:draw(self.currentRoom)
        end
    end
end

function Game:draw_metadata()
    love.graphics.setColor(255, 255, 255)

    self.statusBar:draw()

    if self.player.dead then
        local visitedRooms = 0
        for _,r in pairs(self.rooms) do
            if r.visited then
                visitedRooms = visitedRooms + 1
            end
        end

        cga_print("KILLED " .. #self.player.log:get_kills() .. " MONSTERS\n" ..
                  "DISCOVERED " .. visitedRooms .. " ROOMS",
                  1, 1)
    end
end

function Game:generate()
    self.randomSeed = os.time() + math.random(0, 1000)
    --self.randomSeed = 1344820550
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
    self:switch_to_room(self.rooms[1])
    self:move_player_to_start()
    --self.currentRoom:add_object(self.player)

    -- Put the sword at the first room's midpoint
    for _, item in pairs(self.currentRoom.items) do
        if item.itemType == ITEM_TYPE.sword then
            item:set_position(self.rooms[1].midPoint)
            break
        end
    end

    -- Create a status bar
    self.statusBar = StatusBar(self.player)

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

function Game:input()
    if self.paused then
        return
    end

    -- Get player's directional input
    if love.keyboard.isDown('w') then
        self.player:step(1)
    elseif love.keyboard.isDown('d') then
        self.player:step(2)
    elseif love.keyboard.isDown('s') then
        self.player:step(3)
    elseif love.keyboard.isDown('a') then
        self.player:step(4)
    end
end

function Game:keypressed(key)
    self.player:keypressed(key)

    -- Get player input for switching weapons
    if key == '1' or key == '2' or key == '3' then
        -- Switch to specified weapon number, based on display order
        self.player.armory:switch_to_weapon_number(tonumber(key))
    elseif key == 'lshift' or key == 'rshift' then
        -- Switch to the next weapon
        self.player.armory:switch_to_next_weapon()
    end

    -- Get player input for using items
    if key == 'e' then
        -- Take an elixir
        if self.player:has_item(ITEM_TYPE.elixir) then
            self.player.inventory:get_item(ITEM_TYPE.elixir):use()
        end
    end

    -- Toggle pause
    if key == ' ' then
        if self.paused then
            self:unpause()
        else
            self:pause()
        end
    end

    -- Toggle inventory menu
    if key == 'i' or (self.paused and self.menuState == 'map' and
                      key == 'tab') then
        if self.paused and self.menuState == 'inventory' then
            self:unpause()
        else
            if not self.paused then
                self:pause()
            else
                sound.menuSelect:play()
            end

            self.menuState = 'inventory'
        end

    -- Toggle map
    elseif key == 'm' or (self.paused and self.menuState == 'inventory' and
                          key == 'tab') then
        if self.paused and self.menuState == 'map' then
            self:unpause()
        else
            if not self.paused then
                self:pause()
            else
                sound.menuSelect:play()
            end
        end

        self.menuState = 'map'
    end


    -- If the game is paused
    if self.paused then
        -- If the inventory is open
        if self.menuState == 'inventory' then
            -- Route input to inventory menu
            if self.inventoryMenu:keypressed(key) then
                -- InventoryMenu:keypressed() evaluates to true when the user
                -- exits the menu
                self.paused = false
            end
        end

        -- If the map is open and escape was pressed
        if self.menuState == 'map' and key == 'escape' then
            self.paused = false
        end

        -- Don't allow keys below here
        return
    end


    -- Get player input for shooting arrows
    shootDir = nil
    if key == 'up' then
        shootDir = 1
    elseif key == 'right' then
        shootDir = 2
    elseif key == 'down' then
        shootDir = 3
    elseif key == 'left' then
        shootDir = 4
    end
    if shootDir ~= nil then
        self.player:shoot(shootDir, self.currentRoom)
    end

    -- Get player input for moving when isDown in the input() method didn't see
    -- it
    if key == 'w' then
        self.player:step(1)
    elseif key == 'd' then
        self.player:step(2)
    elseif key == 's' then
        self.player:step(3)
    elseif key == 'a' then
        self.player:step(4)
    end
end

function Game:keyreleased(key)
    if self.player.attackedDir == 1 and key == 'w' then
        self.player.attackedDir = nil
    elseif self.player.attackedDir == 2 and key == 'd' then
        self.player.attackedDir = nil
    elseif self.player.attackedDir == 3 and key == 's' then
        self.player.attackedDir = nil
    elseif self.player.attackedDir == 4 and key == 'a' then
        self.player.attackedDir = nil
    end

    -- If the inventory menu is up
    if self.paused and self.menuState == 'inventory' then
        -- Pass key to inventoryMenu
        self.inventoryMenu:keyreleased(key)
    end
end

function Game:move_player_to_start()
    local room = self.rooms[1]

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
        sound.pause:play()

        -- Reset inventory menu to initial view
        self.inventoryMenu:reset()

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

    -- Update the new current room
    self.currentRoom.fov = nil
    self.currentRoom.bricksDirty = true
    self.currentRoom:update()
end

function Game:unpause()
    if self.paused then
        self.paused = false
    end
end

function Game:update(dt)
    if not self.playedTheme then
        sound.theme:play()
        self.playedTheme = true
    end

    self.statusBar:update()

    if not self.playerMoved and self.time >= 3 then
        self.statusBar:show_context_message({'w', 'a', 's', 'd'}, 'MOVE')
    end
    if self.player.stepped then
        self.playerMoved = true
    end

    if self.paused then
        self.inventoryMenu:update()
        if self.menuState == 'map' then
            self.map:update()
        end

        return
    end

    self:input()

    -- Update the current room
    self.currentRoom:update()

    -- Check if we need to update the adjacent rooms
    for _, room in pairs(self:get_adjacent_rooms()) do
        if room.isGenerated and room ~= self.previousRoom then
            --local needsToUpdate = false

            ---- Check if there are any projectiles
            --for _, s in pairs(room.sprites) do
            --    if instanceOf(Projectile, s) then
            --        needsToUpdate = true
            --        break
            --    end
            --end

            --if needsToUpdate then
                room:update()
            --end
        end
    end

    --if self.previousRoom then
    --    -- Update the previous room
    --    self.previousRoom:update()
    --end

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
