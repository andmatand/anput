require('arrow')
require('fireball')
require('sprite')
require('tile')

-- A Character is a Sprite with AI
Character = class('Character', Sprite)

function Character:init()
	Sprite.init(self)

	Character.static.actions = {dodge = 1, flee = 2, chase = 3, shoot = 4}

	self.frame = 1

	self.health = 100
	self.flashTimer = 0
	self.animateTimer = 0
	self.team = 3

	self.path = {nodes = nil, character = nil, destination = nil}

	-- Default AI levels
	self.ai = {}
	self.ai.dodge = {dist = 0, prob = 0, target = nil}
	self.ai.flee = {dist = 0, prob = 0, target = nil}
	self.ai.chase = {dist = 0, prob = 0, target = nil}
	self.ai.shoot = {dist = 0, prob = 0, target = nil}
	self.aiDelay = 5

	self.aiTimer = 0

	self.magic = {ammo = 0, new = nil}
	self.arrows = {ammo = 0,
	               new = function(owner, dir) return Fireball(owner, dir) end}
	self.currentWeapon = self.arrows
end

function Character:choose_action()
	-- See if there is a projectile we should dodge
	self.ai.dodge.target = nil
	for i,s in pairs(self.room.sprites) do
		if instanceOf(Projectile, s) then
			-- If this is a projectile type that we want to dodge, and if it is
			-- heading toward us
			if self:afraid_of(s) and s:will_hit(self) then
				self.ai.dodge.target = s
			end
		end
	end

	closestDist = 999
	self.closestEnemy = nil
	-- Find closest character on other team
	for _,s in pairs(self.room.sprites) do
		-- If this is a character on the other team
		if instanceOf(Character, s) and s.team ~= self.team then
			dist = manhattan_distance(s.position, self.position)

			-- If it's closer than the current closest
			if dist < closestDist then
				closestDist = dist
				self.closestEnemy = s
			end
		end
	end

	-- Check if there's an enemy in our sights we should shoot
	self.ai.shoot.target = nil
	for _,s in pairs(self.room.sprites) do
		if instanceOf(Character, s) and s.team ~= self.team then
			if self:line_of_sight(s) then
				self.ai.shoot.target = s
			end
		end
	end

	-- If we are not already following a path
	if (self.path.nodes == nil or self:path_obsolete()) then
		-- Set the chase target
		self.ai.chase.target = self.closestEnemy
	end

	-- Set the flee target
	self.ai.flee.target = self.closestEnemy


	-- Clear all old AI probability scores
	for k in pairs(self.ai) do
		self.ai[k].score = 0
	end

	-- Give random scores to each of the AI actions
	for k, a in pairs(self.ai) do
		if a.prob > 0 and a.target ~= nil and
		   manhattan_distance(self.position, a.target.position) <= a.dist then
			a.score = math.random(a.prob, 10)
		else
			a.score = -1
		end
	end

	-- See which action has the best score
	bestScore = 0
	action = nil
	for k,v in pairs(self.ai) do
		if v.score > bestScore then
			bestScore = v.score
			action = Character.actions[k]
			--print('best so far:', k)
		end
	end

	return action
end

function Character:do_ai()
	-- Enforce AI delay
	self.aiTimer = self.aiTimer + 1
	if self.aiTimer >= self.aiDelay then
		self.aiTimer = 0
	else
		return
	end

	-- If we are currently following a path, continue to do that
	if self.path.nodes ~= nil then
		self:follow_path()
		--if self:follow_path() then
		--	return
		--end
	end

	self.action = self:choose_action()

	if self.action == Character.static.actions.dodge then
		print('action: dodge')
		self:dodge(self.ai.dodge.target)
	elseif self.action == Character.static.actions.flee then
		print('action: flee')
		self:flee_from(self.ai.flee.target)
	elseif self.action == Character.static.actions.chase then
		print('action: chase')
		self:chase(self.ai.chase.target)
	elseif self.action == Character.static.actions.shoot then
		print('action: shoot')
		self:shoot(self:direction_to(self.ai.shoot.target.position))
	end
end

function Character:chase(sprite)
	-- Set path to destination
	self:find_path(sprite.position)
	if instanceOf(Character, sprite) then
		self.path.character = sprite
	end

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

function Character:direction_to(position)
	if position.y < self.position.y then
		-- North
		return 1
	elseif position.x > self.position.x then
		-- East
		return 2
	elseif position.y > self.position.y then
		-- South
		return 3
	elseif position.x < self.position.x then
		-- South
		return 4
	end
end

function Character:dodge(sprite)
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

	--self.animateTimer = self.animateTimer + 1
	--if self.animateTimer == 30 then
	--	self.animateTimer = 0

	--	if #self.images > 1 then
	--		if self.frame == 1 and math.random(0, 10) == 0 then
	--			self.frame = 2
	--		else
	--			self.frame = 1
	--		end
	--	end
	--end

	-- Determine which image of this character to draw
	if self.images.moving ~= nil and
	   (self.path.nodes ~= nil or self.moved or
	    self.action == Character.static.actions.flee) then
		img = self.images.moving
	else
		img = self.images.default
	end

	if self.flashTimer == 0 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(img,
						   self.position.x * TILE_W, self.position.y * TILE_H,
						   0, SCALE_X, SCALE_Y)
	else
		self.flashTimer = self.flashTimer - 1
	end
end

function Character:find_path(dest)
	self.path.nodes = self.room:find_path(self.position, dest)
	self.path.destination = dest
end

function Character:follow_path()
	if self.path.nodes == nil then
		return false
	end

	if tiles_touching(self.position, self.path.nodes[1]) then
		self:step(self:direction_to(self.path.nodes[1]))

		-- Pop the step off the path
		table.remove(self.path.nodes, 1)

		if #self.path.nodes == 0 then
			self.path.nodes = nil
		end
	else
		-- We got off the path somehow; abort
		self.path.nodes = nil
		print('aborted path')
		return false
	end

	return true
end

function Character:path_obsolete()
	-- If we're chasing a character
	if self.path.destination ~= nil and self.path.character ~= nil then
		-- If the destination of our path is too far away from where the
		-- character now is
		if manhattan_distance(self.path.destination,
		                      self.path.character.position) > 5 then
			return true
		end
	end
	return false
end

function Character:receive_damage(amount)
	if self.dead then
		return
	end

	self.health = self.health - amount
	self.hurt = true

	if self.health <= 0 then
		self:die()
	end
end

function Character:shoot(dir)
	print('\nshooting...')
	if self.currentWeapon.ammo <= 0 or self.dead then
		return false
	end

	-- If a new projectile was added to the room successfully (did not overlap
	-- with a brick)
	if self.room:add_object(self.currentWeapon.new(self, dir)) ~= false then
		self.currentWeapon.ammo = self.currentWeapon.ammo - 1
	else
		-- The projectile was not added to the room
		return false
	end
	return true
end

function Character:step(dir)
	-- If we just attacked in this direction
	if self.attackedDir == dir then
		return
	else
		-- Clear attackedDir
		self.attackedDir = nil
	end

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

	-- Store this direction for directional attacking
	self.dir = dir
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
