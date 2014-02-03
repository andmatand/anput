require('class.door')
require('class.messagequeue')
require('class.puppet')

-- Outside is a sort of backdrop with puppets which are maniuplated by the
-- Intro and Outro
Outside = class('Outside')

function Outside:init()
    self.puppets = {}
    local puppets = self.puppets

    puppets.museum = Puppet({image = outsideImg.museum.image1,
                             position = {x = 3, y = 9}})

    puppets.temple = Puppet({image = outsideImg.temple.image,
                             position = {x = 14, y = 9},
                             color = MAGENTA})

    local playerY = 2 * puppets.temple.position.y - 1
    puppets.player = Puppet({image = playerImg.default,
                             position = {x = 11, y = playerY}})
    puppets.player.isPlayer = true
    
    -- Create a door for the temple
    self.door = Door({x = (2 * puppets.temple.position.x) + 3,
                      y = (2 * puppets.temple.position.y) - 1})
    self.door.drawBlackness = true
    self.door.drawGlyph = false

    self.museumAvatar = {draw =
        function (position)
            love.graphics.setColor(WHITE)
            love.graphics.draw(outsideImg.museum.avatar,
                               position.x, position.y, 0, SCALE_X, SCALE_Y)
        end}
    self.playerAvatar = {draw =
        function (position)
            love.graphics.setColor(WHITE)
            love.graphics.draw(puppets.player:get_drawable(),
                               position.x, position.y, 0, SCALE_X, SCALE_Y)
        end}

    self.messageQueue = MessageQueue()
end

function Outside:add_dialogue(lines)
    for _, line in pairs(lines) do
        for actor, text in pairs(line) do
            if actor == 'm' then
                self.messageQueue:add(Message({text = text,
                                               avatar = self.museumAvatar}))
            elseif actor == 'p' then
                self.messageQueue:add(Message({text = text,
                                               avatar = self.playerAvatar}))
            end
        end
    end
end

function Outside:draw()
    -- Switch to 2x scale for the museum and temple
    SCALE_X = SCALE_X * 2
    SCALE_Y = SCALE_Y * 2

    love.graphics.push()
    love.graphics.translate(0, -SCALE_Y)

    -- Draw the museum, treating the y position as its bottom
    local x = upscale_x(self.puppets.museum.position.x)
    local y = upscale_y(self.puppets.museum.position.y) -
              ((self.puppets.museum.image:getHeight() - 1) * SCALE_Y)
    self.puppets.museum:draw({x = x, y = y})

    -- Draw the temple, treating the y position as its bottom
    local x = upscale_x(self.puppets.temple.position.x)
    local y = upscale_y(self.puppets.temple.position.y) -
              ((self.puppets.temple.image:getHeight() - 1) * SCALE_Y)
    self.puppets.temple:draw({x = x, y = y})

    love.graphics.pop()

    -- Switch back to normal scale
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    -- Draw the door
    self.door:draw()

    -- Draw the rest of the puppets
    for key, puppet in pairs(self.puppets) do
        if key ~= 'museum' and key ~= 'temple' then
            puppet:draw()
        end
    end

    self.messageQueue:draw()
end

function Outside:key_pressed(key)
    if key == KEYS.SKIP_DIALOGUE then
        -- If there is a message on the queue
        if self.messageQueue.messages[1] then
            -- Skip it
            self.messageQueue.messages[1].finished = true
        end
    end
end

function Outside:update()
    -- Update the puppets
    for _, puppet in pairs(self.puppets) do
        puppet:update()
    end

    self.door:update()
    self.messageQueue:update()
end
