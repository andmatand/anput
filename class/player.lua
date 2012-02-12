require 'class/character.lua'

Player = class('Player', Character)

function Player:init()
	Character.init(self)

	self.images = playerImg
	self.team = 1 -- Good guys

	self.arrows.ammo = 100
	self.magic.ammo = 10
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
		patient:receive_damage(15)
		self.attackedDir = self.dir
	end

	return Character.hit(self, patient)
end

function Player:receive_damage(amount)
	Character.receive_damage(self, amount)

	if not self.dead then
		playerCrySound:play()
	end
end
