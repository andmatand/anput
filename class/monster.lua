require 'class/character.lua'

Monster = class('Monster', Character)

function Monster:init(pos, monsterType)
	Character.init(self)

	self.position = pos
	self.monsterType = monsterType

	self.image = monsterImg[monsterType]
	self.team = 2 -- Enemy team

	-- Set monster AI levels
	if self.monsterType == 1 then
		self.ai.dodge = 10
		self.ai.attack = 5
		self.ai.move = 5
		self.ai.speed = 5
	end
end

function Monster:die()
	self.dead = true
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
