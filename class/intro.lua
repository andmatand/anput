Intro = class('Intro')

function Intro:init()
    self.images = {}

    self.museum = {
        avatar = new_image('museum-avatar.png'),
        image = new_image('museum.png'),
        position = {x = 3, y = 9}
    }
    self.museum.draw =
        function (position)
            love.graphics.draw(self.museum.avatar,
                               position.x, position.y, 0, SCALE_X, SCALE_Y)
        end

    self.temple = {
        image = new_image('temple.png'),
        position = {x = 14, y = 9}
    }

    self.player = Player()
    self.player:set_position({x = 11,
                              y = 15 + (playerImg.default:getHeight() /
                                        SCALE_Y)})
    
    -- Put the player in a fake room
    self.room = Room()
    self.player.room = self.room

    self.player.mirrored = true

    self.door = {timer = love.timer.getTime(), height = 0}

    self:choose_speech()
    table.insert(self.room.messages, Message({text = self.museum.speech,
                                              room = self.room,
                                              avatar = self.museum}))
    table.insert(self.room.messages, Message({text = self.player.speech,
                                              room = self.room,
                                              avatar = self.player}))

    self.state = 'talk'
end

function Intro:choose_speech()
    -- required: EGYPT and ARTIFACT
    -- optional: ARCHAEOLOGY/IST
    local choices = {
        {m = 'PERFORM AN ARCHAEOLOGY IN THE ANCIENT TEMPLE OF EGYPT',
         p = 'AN ARTIFACT WILL BE FOUND'},
        {m = 'GO FIND ARTIFACT IN THE ANCIENT TEMPLE OF EGYPT',
         p = 'RIGHT AWAY BOSS'},
        {m = 'GO DO ARCHAEOLOGY ON THE TEMPLE OF ANPUT GODDESS OF EGYPT',
         p = 'I SHALL RETRIEVE AN ARTIFACT'},
        {m = 'THE MUSEUM NEEDS EGYPT ARTIFACT. DO ARCHAEOLOGY.',
         p = 'OKAY'},
        {m = 'FIND A NEW ARTIFACT OF EGYPT',
         p = 'IT WILL BE AN ARCHAEOLOGY ADVENTURE'},
        {m = 'GO ARCHAEOLOGIST DO YOUR STUFF',
         p = 'I SPECIALIZE IN ARTIFACTS OF EGYPT'},
        {m = 'LOOK A TEMPLE. INVESTIGATE',
         p = 'MAYBE I WILL DISCOVER AN EGYPT ARTIFACT'},
        {m = 'THE MUSEUM IS IN NEED OF EXHIBITION OF EGYPT',
         p = 'I AM AN ARCHAEOLOGIST'},
        {m = 'THE MUSEUM MAY GIVE YOU A PROMOTION',
         p = 'I WILL GET AN ARTIFACT OF EGYPT'},
        {m = 'HEY LOOK AN EGYPT',
         p = 'I WILL FIND AN ARTIFACT'},
        {m = 'IF YOU WANT A PROMOTION PLEASE FIND AN ARTIFACT',
         p = 'I WILL GO TO EGYPT'},
        {m = 'THE MUSEUM EXHIBITION HAS NO ARTIFACTS',
         p = 'I WILL LOOK IN EGYPT'},
        {m = 'THE MUSEUM NEEDS MORE PATRONS',
         p = 'AN ARTIFACT RESIDES IN THE EGYPT TEMPLE'}
    }

    n = math.random(1, #choices)
    self.museum.speech = choices[n].m
    self.player.speech = choices[n].p
end

function Intro:draw()
    -- Switch to 2x scale
    SCALE_X = SCALE_X * 2
    SCALE_Y = SCALE_Y * 2

    love.graphics.draw(self.museum.image,
                       upscale_x(self.museum.position.x),
                       upscale_y(self.museum.position.y) -
                       (self.museum.image:getHeight() * SCALE_Y),
                       0, SCALE_X, SCALE_Y)

    love.graphics.draw(self.temple.image,
                       upscale_x(self.temple.position.x),
                       upscale_y(self.temple.position.y) -
                       (self.temple.image:getHeight() * SCALE_Y),
                       0, SCALE_X, SCALE_Y)

    -- Draw the door opening
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            upscale_x(self.temple.position.x) + (12 * SCALE_X),
                            upscale_y(self.temple.position.y) -
                            self.door.height * SCALE_Y,
                            upscale_x(.5), self.door.height * SCALE_Y)

    -- Switch back to normal scale
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    self.player:draw(nil, 0, self.player.mirrored)

    self.room:draw_messages()
end

function Intro:keypressed(key)
    if key == 'escape' then
        self.finished = true
    elseif key == '.' then
        -- If there is a message on the queue
        if self.room.messages[1] then
            self.room.messages[1].finished = true
        end
    end
end

function Intro:update()
    if self.state == 'talk' then
        if not self.room:update_messages() then
            self.state = 'walk'
            self.player.stepTimer = love.timer.getTime() + .3
        end
    elseif self.state == 'walk' then
        if love.timer.getTime() >= self.player.stepTimer + .1 then
            if self.player:get_position().x < 30 then
                if self.player.mirrored then
                    self.player.mirrored = false
                else
                    self.player:step(2)
                end
            else
                self.state = 'open'
            end
            self.player.stepTimer = love.timer.getTime()
        end
    elseif self.state == 'open' then
        if love.timer.getTime() >= self.door.timer + .2 then
            if self.door.height < 5 then
                self.door.height = self.door.height + 1
            else
                self.state = 'enter'
            end
            self.door.timer = love.timer.getTime()
        end
    elseif self.state == 'enter' then
        self.player:step(2)
        self.finishTimer = love.timer.getTime()
        self.state = 'finish'
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.finishTimer + .2 then
            self.finished = true
        end
    end

    self.player:physics()
    self.player:post_physics()
end
