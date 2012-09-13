local camel = Character()

-- Appearance
camel.name = 'CAMEL'
camel.images = camelImg

-- AI
camel.ai.choiceTimer.delay = 0
camel.team = 2
camel.ai.level.globetrot = {prob = 10, delay = 0}
camel.ai.level.chase = {delay = .1}

-- Mouth
camel.mouth = Mouth({sprite = camel})
camel.mouth.speech = 'AAAAHHH I AM A CAMEL'

camel.update =
    function(self)
        Character.update(self)

        if self.isCaught then
        else
            -- If we are standing next to a character
            for _, c in pairs(self.room:get_characters()) do
                if tiles_touching(c:get_position(), self:get_position()) then
                    -- If the character is grabbing
                    if c.isGrabbing then
                        -- We are caught
                        self.mouth.speech = 'YOU CAUGHT ME'
                        self.mouth:speak(true)
                        self.isCaught = true

                        -- Stop running around
                        self.ai.level.globetrot.prob = nil
                    end
                end
            end
        end
    end

return camel
