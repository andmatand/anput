require 'class/character.lua'

Player = class(Character)

function Player:class_name()
	return 'Player'
end

function Player:die()
	print('player is dead')
end

function Player:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(playerImg,
	                   self.position.x * TILE_W, self.position.y * TILE_H,
	                   0, SCALE_X, SCALE_Y)
end

function Player:hit(patient)
	-- Hit screen edge
	if patient == nil then
		return false
	end

	-- Hit things by default
	self.velocity.x = 0
	self.velocity.y = 0
	return true
end
