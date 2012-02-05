require 'class/sprite.lua'

Character = class(Sprite)

function Character:init()
	self.health = 100
	self.position = {}
	self.velocity = {x = 0, y = 0}
end

function Character:ai(sprites)
	if self.aiType == 1 then
		-- Dodge arrows
		for i,s in pairs(sprites) do
			if s:getClass() == 'Arrow' then
				self:dodge(s)
			end
		end
	end
end

function Character:dodge(sprite)
	if s.velocity.y == -1 then
		-- Moving north
		if s.position.x == self.position.x and
		   s.position.y > self.position.y then
		end
	end
end

function Character:receive_damage(amount)
	self.health = self.health - amount

	if self.health <= 0 then
		 self:die()
	end
end

function Character:shoot(dir, room)
	-- Don't allow shooting directly into a wall
	for i,b in pairs(room.bricks) do
		if tiles_overlap(self.position, b) then
			return false
		end
	end

	-- Spawn a new arrow at the character's coordinates
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
