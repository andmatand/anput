require 'class/sprite.lua'

Character = class(Sprite)

function Character:init()
	self.position = {}
	self.velocity = {x = 0, y = 0}
end

function Character:shoot(dir, room)
	for i,b in pairs(room.bricks) do
		if tiles_overlap(self.position, b) then
			return false
		end
	end

	room:add_sprite(Arrow(self.position, dir))
	return true
end

function Character:step(dir)
	if dir == 1 then
		self.velocity.y = -1
	elseif dir == 2 then
		self.velocity.x = 1
	elseif dir == 3 then
		self.velocity.y = 1
	elseif dir == 4 then
		self.velocity.x = -1
	end
end
