Hieroglyph = class('Hieroglyph')

function Hieroglyph:init(position, letter)
    self.position = {x = position.x, y = position.y}
    self.letter = letter

    self.image = images.hieroglyphs[self.letter]
end

function Hieroglyph:draw(alpha)
    love.graphics.setColor(255, 255, 255, alpha)
    love.graphics.draw(self.image,
                       upscale_x(self.position.x), upscale_y(self.position.y),
                       0, SCALE_X, SCALE_Y)
end

function Hieroglyph:get_position()
    return self.position
end
