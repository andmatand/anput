require 'class/character.lua'

Monster = class(Character)

function Monster:class_name()
	return 'Monster'
end

function Monster:init(pos, monsterType)
	self.position = pos
	self.monsterType = monsterType
end

function Monster:die()
	self.dead = true
end

function Monster:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(monsterImg[self.monsterType],
	                   self.position.x * TILE_W, self.position.y * TILE_H,
	                   0, SCALE_X, SCALE_Y)
end
