require 'class/sprite.lua'

Player = inherit_class(Sprite)

function Player:class_name()
	return 'Player'
end

function Player:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(playerImg,
	                   self.position.x * TILE_W, self.position.y * TILE_H,
	                   0, SCALE_X, SCALE_Y)
end
