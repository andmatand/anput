Hieroglyph = class('Hieroglyph')

function Hieroglyph:init(position, letter)
    self.position = position
    self.letter = letter

    self.image = HIEROGLYPH_IMAGE[self.letter]
end

function Hieroglyph:draw()
    love.graphics.draw(self.image,
                       upscale_x(self.position.x), upscale_y(self.position.y),
                       0, SCALE_X, SCALE_Y)
end
