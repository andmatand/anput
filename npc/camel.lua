local camel = Character()

-- Appearance
camel.name = 'CAMEL'
camel.images = camelImg

-- Give him a thunderstaff as an item only (not a weapon)
camel.inventory:add(ThunderStaff())

-- AI
camel.ai.choiceTimer.delay = 0
camel.team = 2
camel.ai.level.globetrot = {prob = 10, delay = 0}
camel.ai.level.chase = {delay = .1}
camel.ai.level.dodge = {dist = 5, prob = 10, delay = 0}

-- Mouth
camel.mouth = Mouth({sprite = camel})

camel.receive_damage =
    function(self, amount, agent)
        if instanceOf(Player, agent) or
           (agent.owner and instanceOf(Player, agent.owner)) then
            local lines = {'OUCH!', 'OW!'}
            self.mouth.speech = lines[math.random(1, #lines)]
            self.mouth:speak(true)
        end

        camel.class.receive_damage(self, amount, agent)
    end

camel.update =
    function(self)
        camel.class.update(self)

        if self.isCaught then
            local lines = {'WHAT\'S UP', 'ARE YOU THIRSTY? I\'M NOT.'}
            if self.mouth.speech == lines[1] and math.random(1, 3) == 1 then
                self.mouth.speech = lines[2]
            else
                self.mouth.speech = lines[1]
            end

            self.ai:do_action('chase')
        else
            for _, c in pairs(self.room:get_characters()) do
                -- If we are right next to a character
                if tiles_touching(c:get_position(), self:get_position()) then
                    -- If the character is grabbing
                    if c.isGrabbing then
                        -- We are caught
                        self.isCaught = true

                        -- Play a sound
                        sounds.camel.caught:play()

                        -- Say a thing
                        self.mouth.speech = 'YOU CAUGHT ME'
                        self.mouth:speak(true)

                        -- Don't say it again
                        self.mouth.speech = nil

                        -- Stop running around
                        self:step()
                        self.ai:delete_path()
                        self.ai.level.globetrot.prob = nil
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
                    camel.mouth.speech = 'AAAAHHH I AM A CAMEL'
                    self.mouth:speak()
                end
            end
        end
    end

return camel
