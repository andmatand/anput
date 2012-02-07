require 'class/character.lua'

Monster = class('Monster', Character)

function Monster:init(pos, monsterType)
	Character.init(self)

	self.position = pos
	self.monsterType = monsterType
	self.image = monsterImg[monsterType]
end

function Monster:die()
	self.dead = true
end
