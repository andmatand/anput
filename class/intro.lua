require('class.outside')

Intro = class('Intro')

function Intro:init()
    -- Create an outside environment which we can manipulate
    self.outside = Outside()

    -- Start with the player facing left next to the museum
    self.outside.player.position.x = 11
    self.outside.player.dir = 4

    self.outside:add_dialogue(self:choose_speech())
    self.state = 'talk'
end

function Intro:choose_speech()
    -- required: EGYPT and ARTIFACT
    -- optional: ARCHAEOLOGY/IST
    local choices = {
        {{m = 'PLEASE RETRIEVE AN ARTIFACT FROM EGYPT.'},
         {p = 'I WILL DO IT.'}},

        {{m = 'GO FIND AN ARTIFACT IN THE ANCIENT TEMPLE OF EGYPT'},
         {p = 'RIGHT AWAY, BOSS'}},

        {{m = 'GO DO ARCHAEOLOGY ON THE TEMPLE OF ANPUT, GODDESS OF EGYPT'},
         {p = 'I SHALL RETRIEVE AN ARTIFACT'}},

        {{m = 'THE MUSEUM NEEDS AN EGYPTIAN ARTIFACT'},
         {m = 'DO ARCHAEOLOGY'},
         {p = 'I WILL DO THE ARCHAEOLOGY IN THIS TEMPLE.'}},

        {{m = 'FIND A NEW ARTIFACT OF EGYPT'},
         {p = 'IT WILL BE AN ARCHAEOLOGY ADVENTURE'}},

        {{m = 'LOOK A TEMPLE'},
         {m = 'INVESTIGATE'},
         {p = 'MAYBE I WILL DISCOVER AN EGYPT ARTIFACT'}},

        {{m = 'THE MUSEUM IS IN NEED OF AN EGYPT EXHIBIT'},
         {m = 'FIND AN ARTIFACT'},
         {p = 'I WILL CHECK OVER HERE'}},

        {{m = 'IF YOU FIND AN ARTIFACT, YOU WILL GET A PROMOTION'},
         {p = 'I WILL GO TO EGYPT'}},

        {{m = 'THE MUSEUM\'S EGYPT EXHIBIT HAS NO ARTIFACTS'},
         {p = 'I WILL FIND ONE'}},

        {{m = 'THE MUSEUM NEEDS MORE PATRONS'},
         {m = 'A NEW ARTIFACT WILL DRIVE TICKET SALES'},
         {p = 'I WILL FIND AN ARTIFACT IN EGYPT'}}
    }

    n = math.random(1, #choices)
    return choices[n]
end

function Intro:draw()
    self.outside:draw()
end

function Intro:keypressed(key)
    if key == 'escape' then
        self.finished = true
    elseif key == '.' then
        -- If there is a message on the queue
        if self.outside.room.messages[1] then
            -- Skip it
            self.outside.room.messages[1].finished = true
        end
    end
end

function Intro:update()
    if self.state == 'talk' then
        if not self.outside.room:update_messages() then
            self.state = 'walk'
            self.outside.player.stepTimer = love.timer.getTime() + .3
        end
    elseif self.state == 'walk' then
        if love.timer.getTime() >= self.outside.player.stepTimer + .1 then
            if self.outside.player:get_position().x < 30 then
                --self.outside.player.mirrored = false
                self.outside.player:step(2)
            else
                self.state = 'open'
            end
            self.outside.player.stepTimer = love.timer.getTime()
        end
    elseif self.state == 'open' then
        if love.timer.getTime() >= self.outside.door.timer + .2 then
            if self.outside.door.height < self.outside.door.maxHeight then
                self.outside.door.height = self.outside.door.height + 1
            else
                self.state = 'enter'
            end
            self.outside.door.timer = love.timer.getTime()
        end
    elseif self.state == 'enter' then
        self.outside.player:step(2)
        self.finishTimer = love.timer.getTime()
        self.state = 'finish'
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.finishTimer + .2 then
            self.finished = true
        end
    end

    self.outside.player:update()
    self.outside.player:physics()
    self.outside.player:post_physics()
end
