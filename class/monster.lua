require('character')

Monster = class('Monster', Character)

function Monster:init(pos, monsterType)
	Character.init(self)

	self.position = pos
	self.monsterType = monsterType

	self.team = 2 -- Bad guys

	-- Set monster properties
	if self.monsterType == 1 then
		self.images = monsterImg.scarab
		self.health = 10

		self.arrows.ammo = 5
		self.currentWeapon = self.arrows

		self.ai.dodge = 2
		self.ai.flee = 9
		self.ai.shoot = 1

		self.ai.delay = 3
	elseif self.monsterType == 2 then
		self.images = monsterImg.bird
		self.health = 20

		self.arrows.ammo = 10
		self.currentWeapon = self.arrows

		self.ai.dodge = 5
		self.ai.chase = 5
		self.ai.shoot = 1

		self.ai.delay = 5
	elseif self.monsterType == 3 then
		self.images = monsterImg.mummy
		self.health = 40

		self.arrows.ammo = 20
		self.currentWeapon = self.arrows

		self.ai.dodge = 7
		self.ai.chase = 7
		self.ai.shoot = 7

		self.ai.delay = 10
	elseif self.monsterType == 4 then
		self.images = monsterImg.ghost
		self.health = 80

		self.arrows.ammo = 40
		self.currentWeapon = self.arrows

		self.ai.dodge = 9
		self.ai.chase = 1
		self.ai.shoot = 7

		self.ai.delay = 5
	end
end

function Monster:die()
	Character.die(self)

	monsterDieSound:play()
end

function Monster:hit(patient)
	-- Damage other characters
	if instanceOf(Character, patient) then
		if self.team ~= patient.team and -- Not on the same team
		   self.monsterType ~= 4 then -- Not a ghost
			patient:receive_damage(5)
		end
	end

	return Character.hit(self, patient)
end


function Monster:receive_damage(amount)
	Character.receive_damage(self, amount)

	if not self.dead then
		monsterCrySound:play()
	end
end
