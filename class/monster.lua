require 'class/character.lua'

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

		self.ai.dodge = 3
		self.ai.attack = 1
		self.ai.flee = 9
		self.ai.followPath = 8
		self.ai.delay = 5
	elseif self.monsterType == 2 then
		self.images = monsterImg.bird
		self.health = 20

		self.arrows.ammo = 10
		self.currentWeapon = self.arrows

		self.ai.dodge = 5
		self.ai.attack = 1
		self.ai.chase = 5
		self.ai.followPath = 9
		self.ai.delay = 5
	end
end

function Monster:die()
	Character.die(self)

	monsterDieSound:play()
end

function Monster:hit(patient)
	-- Damage other characters depending on monsterType
	if instanceOf(Character, patient) then
		if self.monsterType == 1 then -- Ghost
			patient:receive_damage(05)
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
