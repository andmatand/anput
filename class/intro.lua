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
        {{m = 'PLEASE RETRIEVE AN ARTIFACT FROM EGYPT'},
         {p = 'I WILL DO IT'},
         {p = 'I AM AN ARCHAEOLOGIST'}},

        {{m = 'FIND AN ARTIFACT IN THE ANCIENT TEMPLE OF ANPUT'},
         {m = 'THE ONE IN EGYPT'},
         {p = 'RIGHT AWAY, BOSS'}},

        {{m = 'GO GET AN ARTIFACT FROM THAT TEMPLE OVER THERE'},
         {p = 'YOU MEAN THE TEMPLE OF ANPUT, GODDESS OF THE 17TH NOME OF ' ..
              'UPPER EGYPT?'},
         {m = 'YES'}},

        {{m = 'THE MUSEUM NEEDS AN EGYPTIAN ARTIFACT'},
         {m = 'DO ARCHAEOLOGY'},
         {p = 'I WILL ARCHAEOLOGY SO HARD'}},

        {{m = 'FIND A NEW ARTIFACT IN EGYPT'},
         {p = 'OH BOY'},
         {p = 'IT WILL BE AN ARCHAEOLOGY ADVENTURE'}},

        {{m = 'FIND A NEW ARTIFACT OF EGYPT'},
         {p = 'ARTIFACTS ARE NOT NEW BUT OKAY I WILL DO IT'}},

        {{m = 'LOOK A TEMPLE'},
         {m = 'INVESTIGATE'},
         {p = 'MAYBE I WILL DISCOVER AN EGYPT ARTIFACT'}},

        {{m = 'THE MUSEUM IS IN NEED OF AN EGYPT EXHIBIT'},
         {m = 'FIND AN ARTIFACT'},
         {p = 'I WILL CHECK OVER HERE'}},

        {{m = 'IF YOU FIND AN ARTIFACT, YOU WILL GET A PROMOTION'},
         {p = 'I AM BOUND TO FIND AN ARTIFACT IN EGYPT'}},

        {{m = 'THE MUSEUM\'S EGYPT EXHIBIT HAS NO ARTIFACTS'},
         {p = 'I WILL FIND ONE IN THE TEMPLE OF ANPUT'},
         {m = 'GOOD IDEA'}},

        {{m = 'THE MUSEUM NEEDS MORE PATRONS'},
         {m = 'A NEW ARTIFACT WILL DRIVE TICKET SALES'},
         {p = 'I WILL FIND AN ARTIFACT IN EGYPT'}},

        {{m = 'OBTAIN AN ANCIENT ARTIFACT FOR THE EGYPTOLOGY EXHIBIT'},
         {p = 'OKAY'},
         {m = 'ALSO CAN YOU PICK UP SOME MILK WHILE YOU ARE OUT'}},

        {{m = 'CRISIS HAS STRUCK THE MUSEUM'},
         {m = 'WE ARE ALL OUT OF EGYPTIAN ARTIFACTS'},
         {p = 'I WILL DISCOVER AN ARTIFACT IN EGYPT'},
         {m = 'PLEASE HURRY'}},

        {{m = 'OUR PRIZED EGYPTIAN ARTIFACT HAS BEEN STOLEN BY A ' ..
              'MASKED MAN'},
         {m = 'APREHEND THE THIEF AND RECOVER THE ARTIFACT'},
         {p = 'I\'M ON IT, CHIEF'}},

        {{m = 'A PRICELESS EGYPTIAN ARTIFACT HAS BEEN STOLEN BY A ' ..
              'MASKED WOMAN'},
         {m = 'APREHEND THE THIEF AND RECOVER THE ARTIFACT'},
         {p = 'I\'M ON IT, CHIEF'}}
    }

    n = math.random(1, #choices)
    return choices[n]
end

function Intro:draw()
    self.outside:draw()
end

function Intro:key_pressed(key)
    if key == KEYS.SKIP_CUTSCENE then
        self.finished = true
    elseif key == KEYS.SKIP_DIALOG then
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
        if self.outside.door.state == 'closed' then
            self.outside.door:open()
        elseif self.outside.door.state == 'open' then
            self.state = 'enter'
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

    self.outside.door:update()
    self.outside.player:update()
    self.outside.player:physics()
    self.outside.player:post_physics()
end
