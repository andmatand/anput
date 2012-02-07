require 'class/character.lua'

Player = class('Player', Character)

function Player:init()
	Character.init(self)

	self.image = playerImg
end

function Player:die()
	self.dead = true
	print('player is dead')
end

function Player:hit(patient)
	-- Hit screen edge
	if patient == nil then
		return false
	end

	return Character.hit(self)
end
