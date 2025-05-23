require('util.assets')
require('util.tables')
require('class.game')
require('class.holdablekey')
require('class.intro')
require('class.inventorymenu')
require('class.mainpausemenu')
require('class.menumanager')
require('class.outro')

-- State enumeration
STATE = {BOOT = 1,
         LOAD = 2,
         INTRO = 3,
         GAME = 4,
         INVENTORY_MENU = 5,
         PAUSE_MENU = 6,
         OUTRO = 7}

local function serialize_room(room)
    local msg = ''
    msg = msg .. 'local room = {}\n'
    msg = msg .. 'room.randomSeed = ' .. room.randomSeed .. '\n'
    msg = msg .. 'room.index = ' .. room.index .. '\n'
    if room.requiredZone then
        msg = msg .. 'room.requiredZone = ' ..
                     serialize_table(room.requiredZone)
        msg = msg .. '\n'
    end

    msg = msg .. 'room.exits = {}\n'
    for _, e in pairs(room.exits) do
        msg = msg .. 'table.insert(room.exits, Exit({x = ' .. e.x .. ', ' ..
                                                    'y = ' .. e.y .. '}))'
        msg = msg .. '\n'
    end
    msg = msg .. 'return room'

    return msg
end


-- Start of Class
Wrapper = class('Wrapper')

function Wrapper:init()
    self.fpsLimitTimer = 0

    -- Create a new thread for building rooms in the background
    self.roomBuilderThread = love.thread.newThread('thread/roombuilder.lua')

    -- Create channels to communicate with the roombuilder thread
    self.roomBuilderInputChannel = love.thread.getChannel('roombuilder_input')
    self.roomBuilderOutputChannel = love.thread.getChannel('roombuilder_output')

    -- Start the roombuilder thread
    self.roomBuilderThread:start()

    --local chunk = love.filesystem.load('thread/roombuilder.lua')
    --local result, er = chunk()
    --print(er)

    self.holdableKeys = {}
    for _, key in pairs(KEYS.WALK) do
        self.holdableKeys[key] = HoldableKey(self, key)
    end
    for _, key in pairs(KEYS.SHOOT) do
        self.holdableKeys[key] = HoldableKey(self, key)
    end

    self:find_joystick()

    -- Create a menu manager
    self.pauseMenuManager = MenuManager()

    -- Create a game right away, so we can start generating rooms in the
    -- background
    self:restart()
end

function Wrapper:directional_key_pressed(group, key)
    for dir, k in pairs(KEYBOARD[group]) do
        if key == k then
            self.holdableKeys[KEYS[group][dir]]:press('keyboard')
        end
    end
end

function Wrapper:directional_key_released(group, key)
    for dir, k in pairs(KEYBOARD[group]) do
        if key == k then
            self.holdableKeys[KEYS[group][dir]]:release('keyboard')
        end
    end
end

function Wrapper:draw()
    if self.state == STATE.BOOT then
        -- Start generating the game after we have drawn a black frame
        self.state = STATE.LOAD
    elseif self.state == STATE.INTRO then
        self.intro:draw()
    elseif self.state == STATE.GAME then
        self.game:draw()
    elseif self.state == STATE.INVENTORY_MENU then
        self.game:draw()
        self.inventoryMenu:draw()
    elseif self.state == STATE.PAUSE_MENU then
        self.pauseMenuManager:draw()
    elseif self.state == STATE.OUTRO then
        self.outro:draw()
    end
end

function Wrapper:joystick_added(joystick)
    -- If we don't already have a joystick
    if not self.joystick then
        -- Set the newly connected joystick as our current joystick
        self.joystick = joystick
    end
end

function Wrapper:find_joystick()
    -- If there are any joysticks connected
    if love.joystick.getJoystickCount() > 0 then
        -- Set the first gamepad joystick as our current joystick
        for _, joystick in pairs(love.joystick.getJoysticks()) do
            if joystick:isGamepad() then
                self.joystick = joystick
            end
        end
    else
        self.joystick = nil
    end
end

function Wrapper:joystick_removed(joystick)
    -- If the removed joystick was our current joystick
    if joystick == self.joystick then
        -- Relase all holdable joystick keys
        for name, k in pairs(KEYS['WALK']) do
            self.holdableKeys[k]:release('joystick')
        end
        for name, k in pairs(KEYS['SHOOT']) do
            self.holdableKeys[k]:release('joystick')
        end

        self:pause()

        -- Look for an alternate joystick
        self:find_joystick()
    end
end

function Wrapper:joystick_directional_input(group)
    -- If we don't have a joystick
    if not self.joystick then
        return
    end

    -- Get axis input
    local x = self.joystick:getGamepadAxis(GAMEPAD[group .. '_AXIS_X'])
    local y = self.joystick:getGamepadAxis(GAMEPAD[group .. '_AXIS_Y'])

    local dpad

    -- If a table of buttons are defined for this directional input group
    if GAMEPAD[group] and type(GAMEPAD[group]) == 'table' then
        -- Get d-pad input
        for name, button in pairs(GAMEPAD[group]) do
            if self.joystick:isGamepadDown(button) then
                dpad = button
                break
            end
        end
    end

    local key
    if dpad == 'dpup' or y <= -AXIS_THRESHOLD then
        key = KEYS[group].NORTH
    elseif dpad == 'dpright' or x >= AXIS_THRESHOLD then
        key = KEYS[group].EAST
    elseif dpad == 'dpdown' or y >= AXIS_THRESHOLD then
        key = KEYS[group].SOUTH
    elseif dpad == 'dpleft' or x <= -AXIS_THRESHOLD then
        key = KEYS[group].WEST
    end

    if key then
        -- Press the correct holdable key
        self.holdableKeys[key]:press('joystick')
    end

    -- Release all the walk keys that are not pressed
    for name, k in pairs(KEYS[group]) do
        if k ~= key then
            self.holdableKeys[k]:release('joystick')
        end
    end
end

function Wrapper:gamepad_pressed(joystick, button)
    -- If this input is not for the correct joystick
    if joystick ~= self.joystick then
        return
    end

    -- Check if the button was one of the defined joystick buttons
    for name, b in pairs(GAMEPAD) do
        if name ~= 'SHOOT_AXIS_X' and name ~= 'SHOOT_AXIS_Y' and
           name ~= 'SHOOT' and name ~= 'WALK_AXIS_X' and
           name ~= 'WALK_AXIS_Y' and name ~= 'WALK' then
            if button == b then
                -- Act as if the equivalent keyboard key was pressed
                self:send_keypress(KEYS[name])
            end
        end
    end
end

function Wrapper:gamepad_released(joystick, button)
    -- If this input is not for the correct joystick
    if joystick ~= self.joystick then
        return
    end

    -- Check if the button was one of the defined joystick buttons
    for name, b in pairs(GAMEPAD) do
        if button == b then
            -- Act as if the equivalent keyboard key was released
            self:send_keyrelease(KEYS[name])
        end
    end
end

function Wrapper:key_pressed(key)
    if key == 'lshift' or key == 'rshift' then
        key = 'shift'
    end

    if tonumber(key) then
        if tonumber(key) >= 1 and tonumber(key) <= 9 then
            self:send_keypress(KEYS['WEAPON_SLOT_' .. key])
        end
    end

    for name, k in pairs(KEYBOARD) do
        if name == 'WALK' or name == 'SHOOT' then
            self:directional_key_pressed(name, key)
        else
            if key == k then
                -- If the keypress was consumed
                if self:send_keypress(KEYS[name]) then
                    break
                end
            end
        end
    end
end

function Wrapper:send_keypress(key)
    if self.state == STATE.INTRO then
        self.intro:key_pressed(key)
    elseif self.state == STATE.GAME then
        self.game:key_pressed(key)

        if key == KEYS.INVENTORY then
            -- Pause the game
            self.game:pause()

            -- Play a sound
            sounds.pause:play()

            -- Refresh the inventory menu
            self.inventoryMenu:refresh_items()

            -- Change state to the inventory menu
            self.state = STATE.INVENTORY_MENU

            -- Consume the keypress
            return true
        elseif key == KEYS.PAUSE then
            -- Create a main pause menu and add it to the menu manager
            local mainPauseMenu = MainPauseMenu(self.pauseMenuManager)
            self.pauseMenuManager:push(mainPauseMenu)

            -- Pause all playing sounds
            self.paused_sources = love.audio.pause()

            -- Play the pause sound
            sounds.pause:play()

            -- Change state to the pause menu
            self.state = STATE.PAUSE_MENU

            -- Consume the keypress
            return true
        end
    elseif self.state == STATE.INVENTORY_MENU then
        -- If the inventoryMenu sends the signal that it exited
        if self.inventoryMenu:key_pressed(key) then
            -- Unpause the game
            self.game:unpause()

            -- Go back to the game
            self.state = STATE.GAME

            -- Consume the keypress
            return true
        end

        -- Also send the keypress to the game (for switching weapons)
        self.game:key_pressed(key)
    elseif self.state == STATE.PAUSE_MENU then
        -- If the pauseMenuManager sends the signal that it exited
        if self.pauseMenuManager:key_pressed(key) then
            -- Resume all paused sounds
            love.audio.play(self.paused_sources)

            -- Go back to the game
            self.state = STATE.GAME
        end

        -- Consume the keypress
        return true
    elseif self.state == STATE.OUTRO then
        self.outro:key_pressed(key)
    end
end

function Wrapper:key_released(key)
    for name, k in pairs(KEYBOARD) do
        if name == 'WALK' or name == 'SHOOT' then
            self:directional_key_released(name, key)
        else
            if key == k then
                self:send_keyrelease(KEYS[name])
            end
        end
    end
end

function Wrapper:send_keyrelease(key)
    if self.state == STATE.GAME then
        self.game:key_released(key)
    elseif self.state == STATE.INVENTORY_MENU then
        self.inventoryMenu:key_released(key)
    elseif self.state == STATE.PAUSE_MENU then
        self.pauseMenuManager:key_released(key)
    end
end

function Wrapper:manage_roombuilder_thread()
    -- Check the roomBuilder output channel for a message containing a
    -- pseudo-room object
    local result = self.roomBuilderOutputChannel:pop()

    -- If we got a message
    if result then
        --print('got result from thread!')
        -- Execute the string as Lua code
        local chunk, errorMsg = loadstring(result)

        if errorMsg then
            print('\nresult:\n' .. result .. '\n')
            local f = io.open('thread_result_error.txt', 'w')
            f:write(result)
            f:close()
            print('error in thread result code: ' .. errorMsg)
            return
        end

        local room = chunk()

        local roomIsFromThisGame = true

        -- Find the real room that has the same index
        local realRoom = self.game.rooms[room.index]

        if realRoom then
            if room.randomSeed ~= realRoom.randomSeed then
                -- Room-specific random seed does not match
                roomIsFromThisGame = false
            end
        else
            roomIsFromThisGame = false
        end

        if roomIsFromThisGame then
            -- Attach the psuedo room's member variables to the real room
            for k, v in pairs(room) do
                if k ~= 'exits' then
                    realRoom[k] = v
                end
            end
            realRoom.isBuilt = true
            realRoom.isBeingBuilt = false
        else
            print('rejected room built for previous game')
        end
    end

    -- If the roombuilder input channel does not have a message
    if not self.roomBuilderInputChannel:peek() then
        -- Find the next room that is not built or being built
        local nextRoom = nil
        for _, r in pairs(self.game:get_adjacent_rooms()) do
            if not r.isBuilt and not r.isBeingBuilt then
                nextRoom = r
                break
            end
        end
        if not nextRoom then
            for _, r in pairs(self.game.rooms) do
                if not r.isBuilt and not r.isBeingBuilt then
                    nextRoom = r
                    break
                end
            end
        end

        if nextRoom then
            nextRoom.isBeingBuilt = true

            -- Send another pseduo-room message to the roombuilder thread
            local input = serialize_room(nextRoom)
            self.roomBuilderInputChannel:push(input)
        end
    end
end

function Wrapper:pause()
    if self.game then
        if self.state == STATE.GAME then
            -- Act as if the pause key was pressed
            self:send_keypress(KEYS.PAUSE)
        end
    end
end

function Wrapper:restart()
    -- Stop all playing sounds
    love.audio.stop()

    self.game = Game(self)

    self.state = STATE.BOOT
end

function Wrapper:update(dt)
    if self.state == STATE.BOOT then
        -- Do nothing, so we can get a black frame drawn as fast as possible
        return
    elseif self.state == STATE.LOAD then
        load_assets()
        self.intro = Intro()
    end

    self:joystick_directional_input('WALK')
    self:joystick_directional_input('SHOOT')
    if self.joystickVibration then
        self.joystickVibration:update(dt)

        if not self.joystickVibration.isVibrating then
            self.joystickVibration = nil
        end
    end

    -- Add to timer to limit FPS
    self.fpsLimitTimer = self.fpsLimitTimer + dt

    if self.state == STATE.GAME then
        -- Add to game time
        self.game:add_time(dt)
    end

    -- Change states
    if self.state == STATE.INTRO and self.intro.finished then
        -- Free the memory used by the intro
        self.intro = nil

        -- Switch state to the game
        self.state = STATE.GAME
    elseif self.state == STATE.GAME and self.game.finished then
        -- Create a new outro object
        self.outro = Outro(self.game)

        self.state = STATE.OUTRO
    elseif self.state == STATE.OUTRO and
           self.outro.state == 'go back inside' then
        -- Free the memory used by the outro
        self.outro = nil

        self.state = STATE.GAME
        self.game.finished = false
        self.game:move_player_to_start()
    end

    -- If we have waited long enough between frames
    if self.fpsLimitTimer > 1 / FPS_LIMIT then
        if self.state == STATE.INTRO then
            self.intro:update()
        elseif self.state == STATE.GAME then
            self.game:update()
        elseif self.state == STATE.INVENTORY_MENU then
            self.inventoryMenu:update()

            -- Also update the game (for the status bar and map)
            self.game:update()
        elseif self.state == STATE.PAUSE_MENU then
            self.pauseMenuManager:update()
        elseif self.state == STATE.OUTRO then
            self.outro:update()
        end

        self.fpsLimitTimer = 0
    else -- Do stuff in between frames
        if self.game.map then
            self:manage_roombuilder_thread()

            local numRoomsGenerated = 0
            if not self.game.generatedAllRooms then
                for _, r in pairs(self.game.rooms) do
                    if r.isBuilt and not r.isGenerated then
                        r:generate_next_piece()
                    elseif r.isGenerated then
                        numRoomsGenerated = numRoomsGenerated + 1
                    end
                end
            end

            if numRoomsGenerated == #self.game.rooms then
                local totalTime = love.timer.getTime() - roomGenTimer
                print('generated all ' .. #self.game.rooms .. ' rooms in ' ..
                      totalTime .. ' seconds ' .. '(' ..
                      #self.game.rooms / totalTime .. ' rooms/sec)')
                self.game.generatedAllRooms = true
            end
        else
            -- Generate the map, etc.
            self.game:generate()

            -- Create the inventory menu
            self.inventoryMenu = InventoryMenu(self.game.player)

            -- Start the intro
            self.state = STATE.INTRO
        end
    end
end

function Wrapper:vibrate_joystick(left, right, duration)
    if not self.joystick or not self.joystick:isVibrationSupported() then
        return
    end

    -- If we already have a vibration
    if self.joystickVibration then
        -- Stop the vibration
        self.joystickVibration:stop()
    end

    --  Create a new vibration
    self.joystickVibration = Vibration(self.joystick, left, right, duration)

    -- Start the vibration
    self.joystickVibration:start()
end
