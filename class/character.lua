require 'class/sprite.lua'
require 'util/tile.lua'

Character = class('Character', Sprite)

function Character:init()
	Sprite.init(self)

	self.frame = 1

	self.health = 100
	self.flashTimer = 0
	self.animateTimer = 0
	self.path = nil

	self.team = 3

	self.ai = {}
	self.ai.dodge = 0
	self.ai.chase = 0
	self.ai.flee = 0

	self.ai.attack = 0

	self.ai.delay = 5
	self.ai.followPath = 0

	self.aiTimer = 0

	self.magic = {ammo = 0, new = nil}
	self.arrows = {ammo = 0,
	               new = function(owner, dir) return Arrow(owner, dir) end}
	self.currentWeapon = self.arrows
end

function Character:die()
	self.dead = true
end

function Character:do_ai()
	self.aiTimer = self.aiTimer + 1
	if self.aiTimer >= self.ai.delay then
		self.aiTimer = 0
	else
		return
	end

	if self.path ~= nil then
		if self:follow_path() then
			return
		end
	end

	closestDist = 100
	closestEnemy = nil
	-- Find closest character on other team
	for _,s in pairs(self.room.sprites) do
		-- If this is a character on the other team
		if instanceOf(Character, s) and s.team ~= self.team then
			dist = manhattan_distance(s.position, self.position)

			-- If it's closer than the current closest
			if dist < closestDist then
				closestDist = dist
				closestEnemy = s
			end
		end
	end

	-- Movement
	if self.ai.dodge > 0 and math.random(self.ai.dodge, 10) == 10 then
		-- Dodge arrows
		for i,s in pairs(self.room.sprites) do
			if instanceOf(Arrow, s) then
				if s:will_hit(self) then
					self:dodge(s)
				end
			end
		end
	end
	if self.ai.chase > 0 and math.random(self.ai.chase, 10) == 10 then
		if closestEnemy ~= nil then
			self:chase(closestEnemy)
		end
	end
	if self.ai.flee > 0 and math.random(self.ai.flee, 10) == 10 then
		if closestEnemy ~= nil then
			self:flee_from(closestEnemy)
		end
	end

	-- Shooting
	if self.ai.attack > 0 and math.random(self.ai.attack, 10) == 10 then
		if closestEnemy ~= nil then
			self:attack(closestEnemy)
		end
	end
end

function Character:attack(sprite)
	-- If there is a line of sight to the sprite
	if self:line_of_sight(sprite) then
		-- Shoot it
		self:shoot(self:direction_to(sprite))
	end
end

function Character:chase(sprite)
	-- Set path to destination
	self:find_path(sprite.position)

	-- Start following the path
	self:follow_path()
end

function Character:flee_from(sprite)
	if math.random(0, 1) == 0 then
		if sprite.position.x < self.position.x then
			self:step(2) -- East
		elseif sprite.position.x > self.position.x then
			self:step(4) -- West
		else
			if math.random(0, 1) == 0 then
				self:step(2) else self:step(4)
			end
		end
	else
		if self.position.y > sprite.position.y then
			self:step(3) -- South
		elseif self.position.y < sprite.position.y then
			self:step(1) -- North
		else
			if math.random(0, 1) == 0 then
				self:step(3) else self:step(1)
			end
		end
	end
end

function Character:direction_to(sprite)
	if sprite.position.y < self.position.y then
		-- North
		return 1
	elseif sprite.position.x > self.position.x then
		-- East
		return 2
	elseif sprite.position.y > self.position.y then
		-- South
		return 3
	elseif sprite.position.x < self.position.x then
		-- South
		return 4
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
	if self.images == nil then
		return
	end

	if self.hurt then
		-- Flash if hurt
		self.flashTimer = 5
		self.hurt = false
	end

	self.animateTimer = self.animateTimer + 1
	if self.animateTimer == 30 then
		self.animateTimer = 0

		if #self.images > 1 then
			if self.frame == 1 and math.random(0, 10) == 0 then
				self.frame = 2
			else
				self.frame = 1
			end
		end
	end

	if self.flashTimer == 0 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.images[self.frame],
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
	if math.random(self.ai.followPath, 10) ~= 10 then
		return
	end

	-- DEBUG
	--print('position:', self.position.x, self.position.y)
	--print('path:')
	--for i,p in ipairs(self.path) do
	--	print('  ' .. i, p.x, p.y)
	--end

	if tiles_touching(self.position, self.path[1]) then
		--print('stepping')
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
	if self.currentWeapon.ammo <= 0 or self.dead then
		return
	end

	-- Don't allow shooting directly into a wall
	for i,b in pairs(self.room.bricks) do
		if tiles_overlap(self.position, b) then
			return false
		end
	end

	-- Spawn a new instance of the current weapon at the character's
	-- coordinates
	self.room:add_object(self.currentWeapon.new(self, dir))
	self.currentWeapon.ammo = self.currentWeapon.ammo- 1
	return true
end

function Character:step(dir)
	self.stepped = true
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
