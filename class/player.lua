require 'class/character.lua'

Player = class(Character)

function Player:init()
	self.health = 100
end

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

	if patient:class_name() == 'Brick' then
		self.velocity.x = 0
		self.velocity.y = 0
		return true
	end

	return false
end

function Player:receive_damage(amount)
	self.health = self.health - amount

	if self.health <= 0 then
		 self:die()
	end
end
