require('class.character')

Camel = class('Camel', Character)

function Camel:init()
    Camel.super.init(self)

    -- Appearance
    self.name = 'CAMEL'
    self.images = images.npc.camel

    -- AI
    self.ai.choiceTimer.delay = 0
    self.ai.level.globetrot = {prob = 10, delay = 0}
    self.ai.level.follow = {dist = 8, delay = .1}
    self.ai.level.dodge = {dist = 5, prob = 10, delay = 0}
    self.ai.level.drop = {prob = 10, delay = .5}

    -- Mouth
    self.mouth = Mouth({sprite = self})

    self.state = 'globetrotting'
end

function Camel:forgive()
    self.mouth:set_speech({'OUCH',
                           'OW',
                           'THAT HURTS'})
    self.mouth:speak(true)

    -- Begin fleeing
    self.ai.level.flee = {dist = 5, prob = 9, delay = 0}
end

function Camel:update()
    Camel.super.update(self)

    -- If we have drunk all the water
    if self.state == 'drunk' then
        self.mouth:set_speech({'OH MAN I AM SO FULL',
                               'ARE YOU THIRSTY? I\'M NOT.'})
    -- If we are drinking water
    elseif self.state == 'drinking' then
        if self.drinkTimer.value > 0 then
            self.drinkTimer.value = self.drinkTimer.value - 1
            return
        else
            self.drinkTimer.value = self.drinkTimer.delay
        end

        -- Take a gulp of watertiles
        for i = 1, self.gulpAmount do
            if #self.drinkTiles == 0 then
                break
            end

            -- Drink the first tile in the table
            table.remove(self.drinkTiles, 1)
        end

        -- If there are no more watertiles left to drink
        if #self.drinkTiles == 0 then
            -- Stop drinking
            self.state = 'drunk'

            -- Remove the lake from the room
            remove_value_from_table(self.drinkLake, self.room.lakes)
        else
            -- Update the lake so that the tiles we just removed will not
            -- be visible
            self.drinkLake:refresh_stencil()

            -- Play a gulp sound
            sounds.camel.gulp:play()
        end
    -- If we found water and we are on our way to it
    elseif self.state == 'going to water' then
        -- Check if we are touching a WaterTile
        local touchingTiles = adjacent_tiles(self:get_position())
        local waterTile
        for _, lake in pairs(self.room.lakes) do
            for _, wt in pairs(lake.tiles) do
                for _, t in pairs(touchingTiles) do
                    if tiles_overlap(t, wt) then
                        waterTile = wt
                        break
                    end
                end
                if waterTile then break end
            end
            if waterTile then break end
        end

        -- If we are touching a WaterTile
        if waterTile then
            -- Stop moving
            self.ai:delete_path()
            self.ai.level.follow.prob = nil

            -- Start drinking
            self.state = 'drinking'
            self.drinkTimer = {delay = 4, value = 0}
            self.drinkLake = waterTile.lake
            self.drinkTiles = waterTile.lake.tiles
            self.gulpAmount = #self.drinkTiles / 10
            if self.gulpAmount < 1 then
                self.gulpAmount = 1
            end
        end
    -- If there is a lake in the room
    elseif self.state == 'caught' and #self.room.lakes > 0 then
        -- Get excited
        self.mouth:set_speech({'YESSSS DRINKS', 'WHAAAAAT', 'WATERRRRR'})
        self.mouth:speak(true)

        -- Locate the source water tile in the lake
        local target = self.room.lakes[1].tiles[1]
        target.room = self.room

        -- Run to the water tile
        self.state = 'going to water'
        self.ai.level.follow.target = target
        self.ai.level.follow.delay = 0
        self.ai.level.follow.dist = 0
    -- If we have been caught
    elseif self.state == 'caught' then
        self.mouth:set_speech({'I AM THIRSTY', 'WHAT\'S UP'})
    -- If we are running around and haven't been caught yet
    elseif self.state == 'globetrotting' then
        for _, c in pairs(self.room:get_characters()) do
            -- If we are right next to a character
            if tiles_touching(c:get_position(), self:get_position()) then
                -- If the character is grabbing
                if c.isGrabbing then
                    -- We are caught
                    self.isCaught = true -- Used by the Player class
                    self.state = 'caught'

                    -- Play a sound
                    sounds.camel.caught:play()

                    -- Say a thing
                    self.mouth:set_speech('YOU CAUGHT ME')
                    self.mouth:speak(true)

                    -- Don't say it again
                    self.mouth:set_speech()

                    -- Stop running around
                    self:step()
                    self.ai:delete_path()
                    self.ai.level.globetrot.prob = nil

                    -- Start following the player
                    self.ai.level.follow.prob = 10
                    self.ai.level.follow.target = self.room.game.player
                    break
                end

            -- If we are very close to a player
            elseif instanceOf(Player, c) and
                   manhattan_distance(c:get_position(),
                                      self:get_position()) <= 7 then
                -- Play a sound
                if not self.runSoundTimer or
                   self:get_time() > self.runSoundTimer + 5 then
                   sounds.camel.run:play()
                   self.runSoundTimer = self:get_time()
               end

                -- Yell something funny
                self.mouth:set_speech('AAAAHHH I AM A CAMEL')
                self.mouth:speak()
            end
        end
    end
end

function Camel:wants_item(item)
    if item.weaponType == 'thunderstaff' then
        return true
    else
        return false
    end
end
