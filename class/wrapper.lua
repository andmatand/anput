require('class.game')
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

    -- Create a game right away, so we can start generating rooms in the
    -- background
    self:restart()
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

function Wrapper:keypressed(key)
    if self.state == 'intro' then
        self.intro:keypressed(key)
    elseif self.state == 'outro' then
        self.outro:keypressed(key)
    elseif self.state == 'game' then
        self.game:keypressed(key)
    end
end

function Wrapper:keyreleased(key)
    if self.state == 'game' then
        self.game:keyreleased(key)
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
            --else
                --for i, e in ipairs(room.exits) do
                --    if not tiles_overlap(e:get_position(),
                --                         realRoom.exits[i]:get_position()) then
                --        -- All exits do not match
                --        roomIsFromThisGame = false
                --        break
                --    end
                --end
            end
        else
            roomIsFromThisGame = false
        end

        if roomIsFromThisGame then
            -- Attach psuedo room's member variables to the real room
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

            -- DEBUG: make the player invincible and give him a sword
            --self.game.player.health = 100
            --if not self.game.player.armory.sword then
            --    local sword = Weapon('sword')
            --    self.game.player:pick_up(sword)
            --end
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
