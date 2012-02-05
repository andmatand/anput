require 'class/sprite.lua'

Character = class(Sprite)

function Character:init()
	self.health = 100
	self.position = {}
	self.velocity = {x = 0, y = 0}
	self.aiType = 1 -- DEBUG
end

function Character:ai()
	if self.aiType == 1 then
		-- Dodge arrows
		for i,s in pairs(self.room.sprites) do
			if s:class_name() == 'Arrow' then
				self:dodge(s)
			end
		end
	end
end

function Character:dodge(sprite)
	vel = {}
	if sprite.velocity.y == -1 then
		-- Moving north
		if sprite.position.x == self.position.x and
		   sprite.position.y > self.position.y then
			vel[1] = {{x = -1}, {x = 1}} -- First choice: east or west
			vel[2] = {{y = -1}} -- Second choice: north
		end
	end
	if sprite.velocity.y == 1 then
		-- Moving south
		if sprite.position.x == self.position.x and
		   sprite.position.y < self.position.y then
			vel[1] = {{x = -1}, {x = 1}} -- First choice: east or west
			vel[2] = {{y = 1}} -- Second choice: south
		end
	end

	-- Set the velocity to the best possible choice
	for i,choices in ipairs(vel) do
		while #choices > 0 do
			index = math.random(1, #choices)
			v = choices[index]
			-- If we can't move here
			if self.room:tile_occupied(self:preview_velocity(self.position, v))
			then
				-- Remove this choice from the table
				table.remove(choices, index)
			else
				self.velocity = v
				return
			end
		end
	end
end

function Character:receive_damage(amount)
	self.health = self.health - amount

	if self.health <= 0 then
		 self:die()
	end
end

function Character:shoot(dir)
	-- Don't allow shooting directly into a wall
	for i,b in pairs(self.room.bricks) do
		if tiles_overlap(self.position, b) then
			return false
		end
	end

	-- Spawn a new arrow at the character's coordinates
	self.room:add_sprite(Arrow(self.position, dir))
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
