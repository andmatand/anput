Heiroglyph = class('Heiroglyph')

function Heiroglyph:init(position, letter)
    self.position = position
    self.letter = letter

    self.image = HEIROGLYPH_IMAGE[self.letter]
end

function Heiroglyph:draw()
    love.graphics.draw(self.image,
                       upscale_x(self.position.x), upscale_y(self.position.y),
                       0, SCALE_X, SCALE_Y)
end
