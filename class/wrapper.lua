require('class.game')
require('class.intro')

Wrapper = class('Wrapper')

function Wrapper:init()
    self.fpsTimer = 0

    -- Create a new thread for building rooms in the background
    roombuilder_thread = love.thread.newThread('roombuilder_thread',
                                               'thread/roombuilder.lua')
    roombuilder_thread:start()

    -- Create a game right away, so we can start generating rooms in the
    -- background
    self:restart()
end

function Wrapper:draw()
    if self.state == 'boot' then
        -- Switch to intro after we have drawn a black frame
        self.state = 'intro'
    elseif self.state == 'intro' then
        self.intro:draw()
    elseif self.state == 'game' then
        self.game:draw()
    end
end

function Wrapper:keypressed(key)
    if self.state == 'intro' then
        self.intro:keypressed(key)
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
    local result = roombuilder_thread:get('result')

    -- If we got a message
    if result then
        --print('got result from thread!')
        -- Execute the string as Lua code
        local chunk = loadstring(result)
        local room = chunk()

        local roomIsFromThisGame = true

        -- Find the real room that has the same index
        local realRoom = self.game.rooms[room.index]

        if realRoom then
            if room.randomSeed ~= realRoom.randomSeed then
                -- Room-specific random seed does not match
                roomIsFromThisGame = false
            else
                for i, e in ipairs(room.exits) do
                    if not tiles_overlap(e:get_position(),
                                         realRoom.exits[i]:get_position()) then
                        -- All exits do not match
                        roomIsFromThisGame = false
                        break
                    end
                end
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
    if not roombuilder_thread:peek('input') then
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
            roombuilder_thread:set('input', input)
        end
    end
end


function Wrapper:restart()
    self.game = Game()
    self.intro = Intro()
    self.state = 'boot'
end

function Wrapper:update(dt)
    -- Add to timer to limit FPS
    self.fpsTimer = self.fpsTimer + dt

    self.game:add_time(dt)

    if self.state == 'boot' then
        return
    elseif self.state == 'intro' and self.intro.finished then
        -- Switch state to the game
        self.state = 'game'
    elseif self.state == 'game' and self.game.finished then
        self.state = 'outro'
        print('wrapper: changed state to outro')
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
            love.event.quit()
            --if not self.outro then
            --    self.outro = Outro()
            --end

            --self.outro:update()
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
        end
    end
end