require 'class/sprite.lua'

Player = inherit_class(Sprite)

function Player:class_name()
	return 'Player'
end

function Player:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(playerImg,
	                   self.x * TILE_W,
					   self.y * TILE_H)
end
