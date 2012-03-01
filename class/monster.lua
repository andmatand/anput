require('class/character')

Monster = class('Monster', Character)

Monster.static.difficulties = {
	 1, -- 1. Scarab
	 5, -- 2. Bird
	10, -- 3. mummy
	15, -- 4. cat
	30  -- 5. ghost
	}

function Monster:init(pos, monsterType)
	Character.init(self)

	Monster.static.numMonsterTypes = 5

	self.position = pos
	self.monsterType = monsterType

	self.team = 2 -- Bad guys

	-- Copy monster difficulty level
	self.difficulty = Monster.static.difficulties[monsterType]

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

		self:add_weapon(Weapon('sword'))

		self.aiDelay = 5

		self.ai.dodge = {dist = 5, prob = 5}
		self.ai.chase = {dist = 10, prob = 5}
	elseif self.monsterType == 3 then
		self.images = monsterImg.mummy
		self.health = 40

		self:add_weapon(Weapon('bow'))
		self.currentWeapon:add_ammo(20)

		self.aiDelay = 10

		self.ai.dodge = {dist = 5, prob = 7}
		self.ai.chase = {dist = 20, prob = 7}
		self.ai.shoot = {dist = 10, prob = 7}
	elseif self.monsterType == 4 then
		self.images = monsterImg.cat
		self.health = 40

		self:add_weapon(Weapon('bow'))
		self.currentWeapon:add_ammo(20)

		self.aiDelay = 4

		self.ai.dodge = {dist = 7, prob = 9}
		self.ai.chase = {dist = 10, prob = 9}
		self.ai.shoot = {dist = 15, prob = 5}
	elseif self.monsterType == 5 then
		self.images = monsterImg.ghost
		self.health = 80

		self:add_weapon(Weapon('staff'))
		self.currentWeapon:set_projectile_class(Fireball)
		self.currentWeapon:add_ammo(20)

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

	sound.monsterDie:play()
end

function Monster:hit(patient)
	return Character.hit(self, patient)
end

function Monster:receive_damage(amount)
	Character.receive_damage(self, amount)

	if not self.dead then
		sound.monsterCry:play()
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
