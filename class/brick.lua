Brick = class('Brick')

function Brick:init(coordinates)
    -- X and Y coordinates
    self.x = coordinates.x
    self.y = coordinates.y

    self.isFovObstacle = true
end

function Brick:class_name()
    return 'Brick'
end

function Brick:draw(alpha)
    love.graphics.setColor(1, 0, 1, alpha)
    love.graphics.rectangle('fill', upscale_x(self.x), upscale_y(self.y),
                            TILE_W, TILE_H)
end

function Brick:get_position()
    return {x = self.x, y = self.y}
end

function Brick:is_collidable()
    return true
end

function Brick:receive_hit(agent)
    -- Register as a hit
    return true
end

function Brick:set_position(position)
    self.x = position.x
    self.y = position.y
end
