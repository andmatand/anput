require('class/inventorymenu')
require('class/map')
require('class/player')
require('class/statusbar')
require('util/tables')
require('util/tile')

--local DEBUG = true

-- A Game handles a collection of rooms
Game = class('Game')

function Game:init()
    self.menuState = 'inventory'
    self.paused = false
end

function Game:do_background_jobs()
    if not self.currentRoom then
        return
    end

    for _, room in pairs(self:get_adjacent_rooms()) do
        -- If the room is not completely generated
        if not room.generated then
            room:generate_next_piece()
            break
        end
    end
end

function Game:draw()
    self.currentRoom:draw()

    -- DEBUG: show turrets
    --for _, t in pairs(self.currentRoom.turrets) do
    --  love.graphics.setColor(255, 0, 0)
    --  love.graphics.circle('fill',
    --                       upscale_x(t.position.x) + (upscale_x(1) / 2),
    --                       upscale_y(t.position.y) * (upscale_y(1) / 2),
    --                       upscale_x(1) / 2)
    --end

    if DEBUG then
        -- Show tiles added to make room for required room objects
        if #self.currentRoom.debugTiles > 0 then
            for _, t in pairs(self.currentRoom.debugTiles) do
                love.graphics.setColor(0, 255, 0, 100)
                love.graphics.rectangle('fill', upscale_x(t.x), upscale_x(t.y),
                                        upscale_x(1), upscale_y(1))
            end
        end
    end

    -- DEBUG: show false bricks
    --for _, b in pairs(self.currentRoom.bricks) do
    --    if instanceOf(FalseBrick, b) then
    --        love.graphics.setColor(0, 255, 0, 255)
    --        love.graphics.rectangle('fill', upscale_x(b.x), upscale_x(b.y),
    --                                upscale_x(1), upscale_y(1))
    --    end
    --end


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

    --if self.paused then
    --    love.graphics.setColor(255, 255, 255)
    --    cga_print('PAUSED', 11, 12)
    --end
end

function Game:generate()
    -- Generate a new map
    self.map = Map({game = self})
    self.rooms = self.map:generate()

    -- Create a player
    self.player = Player()

    -- Switch to the first room and put the player at the midPoint
    self:switch_to_room(self.rooms[1])
    self.currentRoom:add_object(self.player)
    self.player:set_position(self.currentRoom.midPoint)

    -- Create a status bar
    self.statusBar = StatusBar(self.player)

    -- Create an inventory menu
    self.inventoryMenu = InventoryMenu(self.player)
end

function Game:get_adjacent_rooms()
    local rooms = {}

    for _, e in pairs(self.currentRoom.exits) do
        table.insert(rooms, e.room)
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
    -- Get player input for switching weapons
    if key == '1' or key == '2' or key == '3' then
        -- Switch to specified weapon number, based on display order
        self.player.armory:switch_to_weapon_number(tonumber(key))
    elseif key == 'lshift' or key == 'rshift' then
        -- Switch to the next weapon
        self.player.armory:switch_to_next_weapon()
    end

    -- Get player input for using items
    if key == 'p' then
        -- Take a potion
        if self.player:has_item(ITEM_TYPE.potion) then
            self.player.inventory:get_item(ITEM_TYPE.potion)[1]:use()
        end
    end

    -- Toggle pause
    if key == ' ' then
        self.paused = not self.paused

        if self.paused then
            --sound.pause:play()

            -- Reset inventory menu to initial view
            self.inventoryMenu:reset()
        end
    end

    -- Toggle inventory menu
    if key == 'i' or (self.menuState == 'map' and key == 'tab') then
        if self.paused and self.menuState == 'inventory' then
            self.paused = false
        else
            if not self.paused then
                -- Reset inventory menu to initial view
                self.inventoryMenu:reset()
                self.paused = true
            else
                sound.menuSelect:play()
            end

            self.menuState = 'inventory'
        end

    -- Toggle map
    elseif key == 'm' or (self.menuState == 'inventory' and key == 'tab') then
        if self.paused and self.menuState == 'map' then
            self.paused = false
        else
            if not self.paused then
                self.paused = true
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

    -- Get player input for trading
    if key == 't' then
        self.player.wantsToTrade = true
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

function Game:switch_to_room(room)
    if DEBUG then
        print('switching to room ' .. room.index)
    end

    prevRoom = self.currentRoom

    -- If there was a previous room
    if prevRoom then
        -- Clear previous room's FOV cache to save memory
        prevRoom.fovCache = {}
    end

    -- Set the new room as the current room
    self.currentRoom = room
    self.currentRoom.visited = true

    if DEBUG then
        print('room distance from start:', self.currentRoom.distanceFromStart)
        print('room difficulty:', self.currentRoom.difficulty)
    end

    -- Make sure room has been completely generated
    if not self.currentRoom.generated then
        self.currentRoom:generate_all()
    end

    -- Update the new current room
    self.currentRoom.fov = nil
    self.currentRoom.bricksDirty = true
    self.currentRoom:update()
end

function Game:update()
    self.statusBar:update()

    if self.paused then
        self.inventoryMenu:update()
        if self.menuState == 'map' then
            self.map:update()
        end

        return
    end

    self:input()

    -- Store which room player was in before this frame
    local oldRoom = self.player.room

    -- Update the current room
    self.currentRoom:update()

    -- Update adjacent rooms that have been generated
    for _, room in pairs(self:get_adjacent_rooms()) do
        if room.generated then
            room:update()
        end
    end

    -- If the player entered a different room
    if self.player.room and self.player.room ~= oldRoom then
        -- Switch the game view to the player's current room
        self:switch_to_room(self.player.room)
    end

    -- Switch rooms when player is on an exit
    --for _, e in pairs(self.currentRoom.exits) do
    --    if tiles_overlap(self.player.position, e) then
    --        break
    --    end
    --end
end
