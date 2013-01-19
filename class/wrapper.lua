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
    self.fpsTimer = 0

    -- Create a new thread for building rooms in the background
    self.roomBuilderThread = love.thread.newThread('roombuilder_thread',
                                                   'thread/roombuilder.lua')
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

function Wrapper:joystick_directional_input(group)
    -- If there is no joystick detected
    if love.joystick.getNumJoysticks() < 1 then
        return
    end

    -- Handle joystick input for walking
    local x = love.joystick.getAxis(1, JOYSTICK[group .. '_AXIS_X'])
    local y = love.joystick.getAxis(1, JOYSTICK[group .. '_AXIS_Y'])
    local hat
    if JOYSTICK[group .. '_HAT'] then
        hat = love.joystick.getHat(1, JOYSTICK[group .. '_HAT'])
    end

    local key
    if hat == 'u' or y == -1 then
        key = KEYS[group].NORTH
    elseif hat == 'r' or x == 1 then
        key = KEYS[group].EAST
    elseif hat == 'd' or y == 1 then
        key = KEYS[group].SOUTH
    elseif hat == 'l' or x == -1 then
        key = KEYS[group].WEST
    end

    if key then
        self.holdableKeys[key]:press('joystick')
    end

    -- Release all the walk keys that are not pressed
    for name, k in pairs(KEYS[group]) do
        if k ~= key then
            self.holdableKeys[k]:release('joystick')
        end
    end
end

function Wrapper:joystick_pressed(joystick, button)
    -- If this input is not for the correct joystick
    if joystick ~= JOYSTICK_NUM then
        return
    end

    -- Check if the button was one of the defined joystick buttons
    for name, b in pairs(JOYSTICK) do
        if name ~= 'SHOOT_AXIS_X' and name ~= 'SHOOT_AXIS_Y' and
           name ~= 'SHOOT_HAT' and name ~= 'WALK_AXIS_X' and
           name ~= 'WALK_AXIS_Y' and name ~= 'WALK_HAT' then
            if button == b then
                -- Act as if the equivalent keyboard key was pressed
                self:send_keypress(KEYS[name])
            end
        end
    end
end

function Wrapper:joystick_released(joystick, button)
    -- If this input is not for the correct joystick
    if joystick ~= JOYSTICK_NUM then
        return
    end

    -- Check if the button was one of the defined joystick buttons
    for name, b in pairs(JOYSTICK) do
        if button == b then
            -- Act as if the equivalent keyboard key was released
            --self:key_released(KEYS[k])
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
    -- Check the brick_layer thread for a message containing a pseudo-room
    -- object
    local result = self.roomBuilderThread:get('result')

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

    -- If the roombuilder thread does not have any input message
    if not self.roomBuilderThread:peek('input') then
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

            -- Send another pseduo-room message
            local input = serialize_room(nextRoom)
            self.roomBuilderThread:set('input', input)
        end
    end
end


function Wrapper:restart()
    self.game = Game(self)
    self.intro = Intro()
    self.state = 'boot'
end

function Wrapper:update(dt)
    if self.state == 'boot' then
        return
    end

    self:joystick_directional_input('WALK')
    self:joystick_directional_input('SHOOT')

    -- Add to timer to limit FPS
    self.fpsTimer = self.fpsTimer + dt

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
    if self.fpsTimer > 1 / FPS then
        if self.state == 'intro' then
            self.intro:update()
        elseif self.state == 'game' then
            self.game:update()
        elseif self.state == 'outro' then
            self.outro:update()
        end

        self.fpsTimer = 0
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
                print('generated all ' .. #self.game.rooms .. ' rooms in ' ..
                      love.timer.getTime() - roomGenTimer .. ' seconds')
                self.game.generatedAllRooms = true
            end
        else
            self.game:generate()

            -- Start the intro after the map is done generating
            self.state = 'intro'
        end
    end
end
