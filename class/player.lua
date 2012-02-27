require('character')

Player = class('Player', Character)

function Player:init()
	Character.init(self)

	self.images = playerImg
	self.team = 1 -- Good guys

	--self:add_weapon('sword')

	--self:add_weapon('bow')
	--self.weapons.bow:add_ammo(100)

	--self:add_weapon('staff')
	--self.weapons.staff:add_ammo(100)
end

function Player:die()
	Character.die(self)

	sound.playerDie:play()
end

function Player:hit(patient)
	-- Ignore screen edge
	if patient == nil then
		return false
	end

	return Character.hit(self, patient)
end

function Player:receive_damage(amount)
	Character.receive_damage(self, amount)

	if not self.dead then
		sound.playerCry:play()
	end
end
