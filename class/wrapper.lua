require('util.assets')
require('class.game')
require('class.holdablekey')
require('class.intro')
require('class.outro')

-- Local functions
local function serialize_table(tbl)
    local str = '{'
    local i = 0
    for k, v in pairs(tbl) do
        i = i + 1
        if i > 1 then
            str = str .. ', '
        end

        str = str .. k .. ' = '

        if type(v) == 'string' then
            str = str .. "'" .. v .. "'"
        elseif type(v) == 'number' then
            str = str .. v
        elseif type(v) == 'table' then
            str = str .. serialize_table(v)
        end
    end
    str = str .. '}'

    return str
end

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
    if self.state == 'boot' then
        -- Start generating the game after we have drawn a black frame
        self.state = 'load'
    elseif self.state == 'intro' then
        self.intro:draw()
    elseif self.state == 'outro' then
        self.outro:draw()
    elseif self.state == 'game' then
        self.game:draw()
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

        if self.game then
            if not self.game.paused then
                -- Act as if the pause key was pressed
                self:send_keypress(KEYS.PAUSE)
            end
        end

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
                self:send_keypress(KEYS[name])
            end
        end
    end
end

function Wrapper:send_keypress(key)
    if self.state == 'intro' then
        self.intro:key_pressed(key)
    elseif self.state == 'outro' then
        self.outro:key_pressed(key)
    elseif self.state == 'game' then
        self.game:key_pressed(key)
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
    if self.state == 'game' then
        self.game:key_released(key)
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

function Wrapper:restart()
    self.game = Game(self)
    self.state = 'boot'
end

function Wrapper:update(dt)
    if self.state == 'boot' then
        -- Do nothing, so we can get a black frame drawn as fast as possible
        return
    elseif self.state == 'load' then
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

    if self.state == 'game' then
        -- Add to game time
        self.game:add_time(dt)
    end

    -- Change states
    if self.state == 'intro' and self.intro.finished then
        -- Free the memory used by the intro
        self.intro = nil

        -- Switch state to the game
        self.state = 'game'
    elseif self.state == 'game' and self.game.finished then
        -- Create a new outro object
        self.outro = Outro(self.game)

        self.state = 'outro'
    elseif self.state == 'outro' and self.outro.state == 'go back' then
        -- Free the memory used by the outro
        self.outro = nil

        self.state = 'game'
        self.game.finished = false
        self.game:move_player_to_start()
    end

    -- If we have waited long enough between frames
    if self.fpsLimitTimer > 1 / FPS_LIMIT then
        if self.state == 'intro' then
            self.intro:update()
        elseif self.state == 'game' then
            self.game:update()
        elseif self.state == 'outro' then
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

            -- Start the intro
            self.state = 'intro'
        end
    end
end

function Wrapper:vibrate_joystick(left, right, duration)
    if not self.joystick or not self.joystick:isVibrationSupported() then
        return
    end

    -- If we already have a vibration
    if self.joystickVibration then
        -- Stop it
        self.joystickVibration:stop()
    end

    --  Create a new vibration
    self.joystickVibration = Vibration(self.joystick, left, right, duration)

    -- Start the vibration
    self.joystickVibration:start()
end
