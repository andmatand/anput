require('class.door')

-- Outside is a sort of backdrop with elements of a room which is maniuplated
-- by the Intro and Outro
Outside = class('Outside')

function Outside:init()
    self.museum = {
        avatar = outsideImg.museum.avatar,
        image = outsideImg.museum.image,
        position = {x = 3, y = 9}
    }
    self.museum.draw =
        function (position)
            love.graphics.draw(self.museum.avatar,
                               position.x, position.y, 0, SCALE_X, SCALE_Y)
        end

    self.temple = {
        image = outsideImg.temple.image,
        position = {x = 14, y = 9}
    }

    self.player = Player()
    self.player:set_position({x = 11,
                              y = 15 + (playerImg.default:getHeight() /
                                        4)})
    
    -- Put the player in a fake room
    self.room = Room()
    self.player.room = self.room

    self.door = Door({x = (2 * self.temple.position.x) + 3,
                      y = (2 * self.temple.position.y) - 1.25})
end

function Outside:add_dialogue(lines)
    for _, line in pairs(lines) do
        for actor, text in pairs(line) do
            if actor == 'm' then
                table.insert(self.room.messages,
                             Message({text = text,
                                      room = self.room,
                                      avatar = self.museum}))
            elseif actor == 'p' then
                table.insert(self.room.messages,
                             Message({text = text,
                                      room = self.room,
                                      avatar = self.player}))
            end
        end
    end
end

function Outside:draw()
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

    -- Switch back to normal scale
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    -- Draw the door opening
    self.door:draw()

    self.player:draw(nil, 0)

    self.room:draw_messages()
end
