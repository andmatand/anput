require('class.outside')

Intro = class('Intro')

function Intro:init()
    -- Create an outside environment which we can manipulate
    self.outside = Outside()

    -- Start with the player facing left next to the museum
    self.outside.puppets.player.position.x = 11
    self.outside.puppets.player.dir = 4

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

        {{m = 'IT IS TIME TO FIND A NEW ARTIFACT IN EGYPT'},
         {p = 'OH BOY'},
         {p = 'IT WILL BE AN ARCHAEOLOGY ADVENTURE'}},

        {{m = 'UNDERTAKE AN EXPEDITION TO EGYPT'},
         {m = 'FIND THE HIDDEN ARTIFACT IN THE TEMPLE OF ANPUT'},
         {p = 'I SHALL NOT FAIL'}},

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

        {{m = 'HEY CAN YOU GO GET AN ARTIFACT FOR THE EGYPTOLOGY EXHIBIT?'},
         {p = 'OKAY'},
         {m = 'THX'}},

        {{m = 'CRISIS HAS STRUCK THE MUSEUM'},
         {m = 'WE ARE ALL OUT OF EGYPTIAN ARTIFACTS'},
         {p = 'I WILL DISCOVER AN ARTIFACT IN EGYPT'},
         {m = 'PLEASE HURRY'}},

        {{m = 'OUR ' ..
              (love.math.random(0, 1) == 0 and 'PRIZED' or 'PRICELESS') ..
              ' ' ..
              'EGYPTIAN ARTIFACT HAS BEEN STOLEN BY A MASKED ' ..
              (love.math.random(0, 1) == 0 and 'MAN' or 'WOMAN')},
         {m = 'APREHEND THE THIEF AND RECOVER THE ARTIFACT'},
         {p = 'I\'M ON IT, CHIEF'}}
    }

    n = love.math.random(1, #choices)
    return choices[n]
end

function Intro:draw()
    self.outside:draw()
end

function Intro:key_pressed(key)
    if key == KEYS.SKIP_CUTSCENE then
        self.finished = true
    else
        self.outside:key_pressed(key)
    end
end

function Intro:update()
    if self.state == 'talk' then
        if self.outside.messageQueue:is_empty() then
            self.state = 'walk'
            self.outside.puppets.player:walk(2, 19, 2)
        end
    elseif self.state == 'walk' then
        if self.outside.puppets.player:get_position().x == 30 then
            self.state = 'open'
        end
    elseif self.state == 'open' then
        if self.outside.door.state == 'closed' then
            self.outside.door:open()
        elseif self.outside.door.state == 'open' then
            self.state = 'enter'
        end
    elseif self.state == 'enter' then
        self.outside.puppets.player:walk(2)
        self.finishTimer = love.timer.getTime()
        self.state = 'finish'
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.finishTimer + .2 then
            self.finished = true
        end
    end

    self.outside:update()
end
