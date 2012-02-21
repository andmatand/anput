require('character')

Monster = class('Monster', Character)

function Monster:init(pos, monsterType)
	Character.init(self)

	Monster.static.numMonsterTypes = 5

	self.position = pos
	self.monsterType = monsterType

	self.team = 2 -- Bad guys

	-- Set monster properties
	if self.monsterType == 1 then
		self.images = monsterImg.scarab
		self.health = 10

		self.aiDelay = 3

		self.ai.dodge = {dist = 5, prob = 2}
		self.ai.flee = {dist = 15, prob = 9}
	elseif self.monsterType == 2 then
		self.images = monsterImg.bird
		self.health = 20

		self.aiDelay = 5

		self.ai.dodge = {dist = 5, prob = 5}
		self.ai.chase = {dist = 10, prob = 5}
	elseif self.monsterType == 3 then
		self.images = monsterImg.mummy
		self.health = 40

		self.arrows.ammo = 20
		self.currentWeapon = self.arrows

		self.aiDelay = 10

		self.ai.dodge = {dist = 5, prob = 7}
		self.ai.chase = {dist = 20, prob = 7}
		self.ai.shoot = {dist = 10, prob = 7}
	elseif self.monsterType == 4 then
		self.images = monsterImg.cat
		self.health = 40

		self.arrows.ammo = 20
		self.currentWeapon = self.arrows

		self.aiDelay = 4

		self.ai.dodge = {dist = 7, prob = 9}
		self.ai.chase = {dist = 10, prob = 9}
		self.ai.shoot = {dist = 15, prob = 5}
	elseif self.monsterType == 5 then
		self.images = monsterImg.ghost
		self.health = 80

		self.arrows.ammo = 40
		self.currentWeapon = self.arrows

		self.aiDelay = 2

		self.ai.dodge = {dist = 5, prob = 9}
		self.ai.chase = {dist = 20, prob = 1}
		self.ai.shoot = {dist = 10, prob = 7}
	end
end

function Monster:afraid_of(sprite)
	if instanceOf(Arrow, sprite) then
		-- Ghost
		if self.monsterType == 5 then
			return false
		end
	end

	return true
end

function Monster:die()
	Character.die(self)

	monsterDieSound:play()
end

function Monster:hit(patient)
	-- Damage other characters
	if instanceOf(Character, patient) then
		if self.team ~= patient.team and -- Not on the same team
		   self.monsterType ~= 5 then -- Not a ghost
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

function Monster:receive_hit(agent)
	if self.monsterType == 5 then -- A ghost
		-- Only magic hits ghosts
		if instanceOf(Fireball, agent) then
			return true
		else
			return false
		end
	end

	return Character.receive_hit(self, agent)
end
