require 'class/character.lua'

Player = class('Player', Character)

function Player:init()
	Character.init(self)

	print('player velocity:', self.velocity)
end

function Player:die()
	self.dead = true
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

	return Character.hit(self)
end
