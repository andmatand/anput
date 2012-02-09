require 'class/sprite.lua'
require 'util/tile.lua'

Character = class('Character', Sprite)

function Character:init()
	Sprite.init(self)

	self.health = 100
	self.flashTimer = 0
	self.aiType = 1 -- DEBUG
	self.path = nil
end

function Character:ai()
	if self.path ~= nil then
		if self:follow_path() then
			return
		end
	end

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
	if manhattan_distance(self.position, sprite.position) > 5 then
		return
	end

	-- Determine which direction we should search
	if sprite.velocity.y == -1 then
		-- Sprite is moving north, so search north
		searchDir = 1
	elseif sprite.velocity.x == 1 then
		-- Sprite is moving east, so search east
		searchDir = 2
	elseif sprite.velocity.y == 1 then
		-- Sprite is moving south, so search south
		searchDir = 3
	elseif sprite.velocity.x == -1 then
		-- Sprite is moving west, so search west
		searchDir = 4
	else
		-- Sprite is not moving; nothing to dodge
		return
	end

	-- Find the nearest tile which is out of the path of the projectile
	x = self.position.x
	y = self.position.y
	destination = nil
	switchedDir = false
	firstLoop = true
	while destination == nil do
		-- Add the lateral tiles
		if searchDir == 1 then
			laterals = {{x = x - 1, y = y}, {x = x + 1, y = y}}
		elseif searchDir == 2 then
			laterals = {{x = x, y = y - 1}, {x = x, y = y + 1}}
		elseif searchDir == 3 then
			laterals = {{x = x - 1, y = y}, {x = x + 1, y = y}}
		elseif searchDir == 4 then
			laterals = {{x = x, y = y - 1}, {x = x, y = y + 1}}
		end

		-- If the center tile is occupied
		if firstLoop == false and self.room:tile_occupied({x = x, y = y}) then
			if switchedDir == false then
				-- We can't get to the lateral tiles, start searching in the
				-- other direction
				for i = 1,2 do -- Increment direction by two, wrapping around
					searchDir = searchDir + 1
					if searchDir > 4 then
						searchDir = 1
					end
				end
				x = self.position.x
				y = self.position.y
				switchedDir = true
			else
				-- We already tried the other direction; abort
				break
			end
		else
			while #laterals > 0 do
				index = math.random(1, #laterals)
				choice = laterals[index]

				-- If this tile choice is occupied
				if self.room:tile_occupied(choice) then
					-- Remove this choice from the table
					table.remove(laterals, index)
				else
					destination = choice
					break
				end
			end
		end

		-- Move to forward/back from the sprite we're trying to dodge
		if searchDir == 1 then
			y = y - 1
		elseif searchDir == 2 then
			x = x + 1
		elseif searchDir == 3 then
			y = y + 1
		elseif searchDir == 4 then
			x = x - 1
		end

		firstLoop = false
	end

	if destination ~= nil then
		-- Set path to destination
		self:find_path(destination)

		-- Start following the path
		self:follow_path()
	end
end

function Character:draw()
	if self.image == nil then
		return
	end

	if self.hurt then
		-- Flash if hurt
		self.flashTimer = 3
		self.hurt = false
	end

	if self.flashTimer == 0 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.image,
						   self.position.x * TILE_W, self.position.y * TILE_H,
						   0, SCALE_X, SCALE_Y)
	else
		self.flashTimer = self.flashTimer - 1
	end
end

function Character:find_path(dest)
	self.path = self.room:find_path(self.position, dest)
end

function Character:follow_path()
	-- DEBUG
	print('position:', self.position.x, self.position.y)
	print('path:')
	for i,p in ipairs(self.path) do
		print('  ' .. i, p.x, p.y)
	end

	if tiles_touching(self.position, self.path[1]) then
		print('stepping')
		self:step_toward(self.path[1])

		-- Pop the step off the path
		table.remove(self.path, 1)

		if #self.path == 0 then
			self.path = nil
		end
	else
		-- We got off the path somehow; abort
		self.path = nil
		print('aborted path')
	end
end

function Character:hit(patient)
	return Sprite.hit(self, patient)
end

function Character:receive_damage(amount)
	self.health = self.health - amount
	self.hurt = true

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
		self.velocity.x = 0
		self.velocity.y = -1
	elseif dir == 2 then
		self.velocity.x = 1
		self.velocity.y = 0
	elseif dir == 3 then
		self.velocity.x = 0
		self.velocity.y = 1
	elseif dir == 4 then
		self.velocity.x = -1
		self.velocity.y = 0
	end
end

function Character:step_toward(dest)
	if self.position.x < dest.x then
		self:step(2)
	elseif self.position.x > dest.x then
		self:step(4)
	elseif self.position.y < dest.y then
		self:step(3)
	elseif self.position.y > dest.y then
		self:step(1)
	end
end

function Character:cheap_follow_path(dest)
	if self.position.x == dest.x and self.position.y == dest.y then
		return
	end

	xDist = math.abs(dest.x - self.position.x)
	yDist = math.abs(dest.y - self.position.y)

	-- Move on the axis farthest away first
	if xDist > yDist then
		if self.position.x < dest.x then
			self:step(2)
		else
			self:step(4)
		end
	else
		if self.position.y < dest.y then
			self:step(3)
		else
			self:step(1)
		end
	end

	return true
end
