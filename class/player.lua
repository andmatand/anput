require 'class/character.lua'

Player = class('Player', Character)

function Player:init()
	Character.init(self)

	self.image = playerImg
	self.team = 1 -- Good guys
end

function Player:die()
	self.dead = true
	print('player is dead')
end

function Player:hit(patient)
	-- Ignore screen edge
	if patient == nil then
		return false
	end

	-- Damage other characters with sword
	if instanceOf(Character, patient) then
		patient:receive_damage(20)
	end

	return Character.hit(self, patient)
end
