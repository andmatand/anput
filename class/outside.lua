-- Outside is a sort of backdrop with elements of a room which is maniuplated
-- by the Intro and Outro
Outside = class('Outside')

function Outside:init()
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
                                        4)})
    
    -- Put the player in a fake room
    self.room = Room()
    self.player.room = self.room

    self.door = {timer = love.timer.getTime(), height = 0}
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
