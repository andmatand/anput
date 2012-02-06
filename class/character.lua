require 'class/sprite.lua'
require 'util/tile.lua'

Character = class('Character', Sprite)

function Character:init()
	Sprite.init(self)

	self.health = 100
	self.aiType = 1 -- DEBUG
end

function Character:ai()
	if self.aiType == 1 then
		-- Dodge arrows
		for i,s in pairs(self.room.sprites) do
			if instanceOf(Arrow, s) then
				if s:will_hit(self) then
					self:dodge(s)
				end
			end
		end
	end
end

function Character:dodge(sprite)
	if manhattan_distance(self.position, sprite.position) > 7 then
		return
	end

	vel = {}
	if sprite.velocity.y == -1 then
		-- Moving north
		if sprite.position.x == self.position.x and
		   sprite.position.y > self.position.y then
			vel[1] = {{x = -1}, {x = 1}} -- First choice: east or west
			vel[2] = {{y = -1}} -- Second choice: north
			vel[3] = {{y = 1}} -- Third choice: south
		end
	end
	if sprite.velocity.y == 1 then
		-- Moving south
		if sprite.position.x == self.position.x and
		   sprite.position.y < self.position.y then
			vel[1] = {{x = -1}, {x = 1}} -- First choice: east or west
			vel[2] = {{y = 1}} -- Second choice: south
			vel[3] = {{y = -1}} -- Third choice: north
		end
	end
	if sprite.velocity.x == -1 then
		-- Moving west
		if sprite.position.y == self.position.y and
		   sprite.position.x > self.position.x then
			vel[1] = {{y = -1}, {y = 1}} -- First choice: north or south
			vel[2] = {{x = -1}} -- Second choice: west
			vel[3] = {{x = 1}} -- Third choice: east
		end
	end
	if sprite.velocity.x == 1 then -- Moving east
		if sprite.position.y == self.position.y and
		   sprite.position.x < self.position.x then
			vel[1] = {{y = -1}, {y = 1}} -- First choice: north or south
			vel[2] = {{x = 1}} -- Second choice: east
			vel[3] = {{x = -1}} -- Third choice: west
		end
	end

	-- Set the velocity to the best possible choice
	for i,choices in ipairs(vel) do
		print('dodge: considering choice ' .. i)
		while #choices > 0 do
			-- DEBUG
			for j,c in pairs(choices) do
				print('  ', c.x, c.y)
			end

			index = math.random(1, #choices)
			v = choices[index]
			-- If we can't move here
			if self.room:tile_occupied(self:preview_velocity(v)) then
				-- Remove this choice from the table
				table.remove(choices, index)
				print('dodge: removed choice')
			else
				self.velocity = v
				print('dodge: accepted velocity', v.x, v.y)
				return
			end
		end
	end
end

function Character:hit()
	return Sprite.hit(self)
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
