require('class/mouth')
require('class/sprite')
require('util/tile')
require('class/weapon')

-- A Character is a Sprite with AI
Character = class('Character', Sprite)

function Character:init()
	Sprite.init(self)

	Character.static.actions = {dodge = 1, flee = 2, chase = 3, shoot = 4}

	self.frame = 1

	self.health = 100
	self.hurtTimer = love.timer.getTime()
	self.flashTimer = 0
	self.team = 1 -- Good guys
	self.isCorporeal = true

	self.path = {nodes = nil, character = nil, destination = nil}

	-- Default AI levels
	self.ai = {}
	self.ai.dodge = {dist = 0, prob = 0, target = nil}
	self.ai.flee = {dist = 0, prob = 0, target = nil}
	self.ai.chase = {dist = 0, prob = 0, target = nil}
	self.ai.shoot = {dist = 0, prob = 0, target = nil}
	self.aiDelay = 5

	self.aiTimer = 0

	self.weapons = {}
	self.currentWeapon = nil

	self.inventory = {}
end

function Character:add_health(amount)
	if self.dead then
		return false
	end

	if self.health < 100 then
		self.health = self.health + amount

		if self.health > 100 then
			self.health = 100
		end

		-- Play sound depending on who gained health
		if instanceOf(Player, patient) then
			sound.playerGetHP:play()
		elseif instanceOf(Monster, patient) then
			sound.monsterGetHP:play()
		end

		return true
	end

	return false
end

function Character:add_to_inventory(item)
	item.position = nil
	item.owner = self
	table.insert(self.inventory, item)
end

function Character:remove_from_inventory(item)
	for i, v in pairs(self.inventory) do
		if v == item then
			table.remove(self.inventory, i)
			return
		end
	end
end

function Character:add_weapon(weapon)
	local firstWeapon

	-- If we currently have no weapons
	if not next(self.weapons) then
		firstWeapon = true
	else
		firstWeapon = false
	end

	-- Create a new weapon and add it to our weapons table
	self.weapons[weapon.name] = weapon
	weapon.owner = self

	if firstWeapon then
		-- Set this new weapon as the current weapon
		self.currentWeapon = weapon
	end
end

function Character:afraid_of(sprite)
	if instanceOf(Arrow, sprite) then
		-- Ghost
		if self.monsterType == 5 then
			return false
		end
	end

	return true
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

	local closestDist = 999
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
	if not self.path.nodes or self:path_obsolete() then
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
		if a.prob > 0 and a.target and
		   manhattan_distance(self.position, a.target.position) <= a.dist then
			a.score = math.random(a.prob, 10)
		else
			a.score = -1
		end
	end

	-- See which action has the best score
	local bestScore = 0
	local action = nil
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
	if self.path.nodes then
		self:follow_path()
		--if self:follow_path() then
		--	return
		--end
	end

	self.action = self:choose_action()

	if self.action == Character.static.actions.dodge then
		--print('action: dodge')
		self:dodge(self.ai.dodge.target)
	elseif self.action == Character.static.actions.flee then
		--print('action: flee')
		self:flee_from(self.ai.flee.target)
	elseif self.action == Character.static.actions.chase then
		--print('action: chase')
		self:chase(self.ai.chase.target)
	elseif self.action == Character.static.actions.shoot then
		--print('action: shoot')
		self:shoot(self:direction_to(self.ai.shoot.target.position))
	end
end

function Character:die()
	Sprite.die(self)

	local itemsToDrop = {}

	-- If we have any items in our inventory
	if self.inventory then
		for _, i in pairs(self.inventory) do
			table.insert(itemsToDrop, i)
		end
		self.inventory = {}
		print('Dropping ' .. #itemsToDrop .. ' items...')
	end

	-- If we have any weapons
	if self.weapons then
		for _, w in pairs(self.weapons) do
			-- If the player doesn't already have this weapon, or we are the
			-- player
			if (not self.room.game.player.weapons[w.name] or
			    instanceOf(Player, self)) then
				-- Make an item version of this weapon
				local newItem = Item()
				newItem.weapon = w
				table.insert(itemsToDrop, newItem)
			end
		end
		self.weapons = {}
	end

	-- Drop them
	self:drop(itemsToDrop)
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
	else
		-- The target position is the same as our position
		return math.random(1, 4)
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
	while not destination do
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
		if (firstLoop == false and
		    not self.room:tile_walkable({x = x, y = y})) then
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
				if not self.room:tile_walkable(choice) then
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

function Character:draw(pos)
	if not self.images then
		return
	end

	pos = pos or self.position

	if self.flashTimer == 0 then
		if self.color then
			love.graphics.setColor(self.color)
		else
			love.graphics.setColor(255, 255, 255)
		end
		love.graphics.draw(self.currentImage,
		                   pos.x * TILE_W * SCALE_X, pos.y * TILE_H * SCALE_Y,
		                   0, SCALE_X, SCALE_Y)
	else
		self.flashTimer = self.flashTimer - 1
	end
end

function Character:drop(items)
	-- Find all neighboring tiles
	local neighbors = find_neighbor_tiles(self.position)

	-- Assign positions to the items and add them to the room
	local i = 0
	for _, item in pairs(items) do
		i = i + 1

		if i == 1 and self.dead then
			-- Position the item where we just died
			item.position = self.position
		else
			-- Make a working copy of neighbors
			local tempNeighbors = copy_table(neighbors)

			-- Try to find a free neighboring tile
			while not item.position and #tempNeighbors > 0 do
				-- Choose a random neighboring tile
				local neighborIndex = math.random(1, #tempNeighbors)
				local n = tempNeighbors[neighborIndex]

				-- If the spot is free
				if self.room:tile_is_droppoint(n) then
					-- Use this position
					item.position = {x = n.x, y = n.y}
					break
				else
					-- Remove it from the working copy of neighbors
					table.remove(tempNeighbors, neighborIndex)
				end
			end

			-- If the item still doesn't have a position
			if not item.position then
				-- Make a working copy of neighbors
				local tempNeighbors = copy_table(neighbors)

				-- Find a neighboring tile which is inside the room
				while not item.position and #tempNeighbors > 0 do
					local neighborIndex = math.random(1, #tempNeighbors)
					local n = tempNeighbors[neighborIndex]

					if self.room:tile_in_room(n) then
						-- Use this position
						item.position = {x = n.x, y = n.y}
						break
					else
						-- Remove it from the working copy of neighbors
						table.remove(tempNeighbors, neighborIndex)
					end
				end
			end
		end

		-- Add the item to the room
		self.room:add_object(item)

		print('dropped item ' .. i)
	end
end

function Character:find_path(dest)
	self.path.nodes = self.room:find_path(self.position, dest)
	self.path.destination = dest
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

function Character:follow_path()
	if not self.path.nodes then
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

function Character:hit(patient)
	-- Damage other characters with sword
	if (instanceOf(Character, patient) and -- We hit a character
		self.currentWeapon and -- We have a weapon
	    self.currentWeapon.name == 'sword' and -- Current weapon is sword
		self.team ~= patient.team) then -- Not on the same team
		-- If the patient receives our hit
		if patient:receive_hit(self) then
			patient:receive_damage(self.currentWeapon.damage)
			self.attackedDir = self.dir
		else
			return false
		end
	end

	return Sprite.hit(self, patient)
end

function Character:path_obsolete()
	-- If we're chasing a character
	if self.path.destination and self.path.character then
		-- If the destination of our path is too far away from where the
		-- character now is
		if manhattan_distance(self.path.destination,
		                      self.path.character.position) > 5 then
			return true
		end
	end
	return false
end

function Character:pick_up(item)
	-- If the item is already being held by someone, or is already used up
	if item.owner or item.isUsed then
		return
	end

	-- If it's a weapon-item
	if item.weapon then
		-- If we don't already have this type of weapon
		if not self.weapons[item.weapon.name] then
			self:add_weapon(item.weapon)
			item.owner = self
		end

		-- Apply any arrow packs we have
		for _, i in pairs(self.inventory) do
			if i.itemType == 1 then
				i:use()
			end
		end
	elseif self.weapons.bow and item.itemType == 1 then
		-- Apply arrows to bow instead of putting them in inventory
		item:use_on(self)
	else
		-- It's a normal item; add it to our inventory
		self:add_to_inventory(item)
	end

	if item.owner or item.isUsed then
		-- Play sound depending on who picked it up
		if instanceOf(Player, self) then
			sound.playerGetItem:play()
		elseif instanceOf(Monster, self) then
			sound.monsterGetItem:play()
		end
	end
end

function Character:receive_damage(amount)
	if self.dead then
		return
	end

	self.health = self.health - amount
	self.hurt = true
	self.hurtTimer = love.timer.getTime()

	if self.health <= 0 then
		self.health = 0
		self:die()
	end
end

function Character:receive_hit(agent)
	-- If the agent is a projectile
	if instanceOf(Projectile, agent) then
		-- If it has an owner
		if agent.owner then
			-- If the owner is on our team
			if agent.owner.team == self.team then
				-- Turn against him
				self.speech = "THAT WAS NOT VERY NICE"
				self.team = 3
			end
		end
	end

	return Sprite.receive_hit(self)
end

function Character:recharge()
	local slow = .25
	local fast = .5
	local amount

	-- If we didn't move
	if not self.moved then
		-- Recharge faster
		amount = fast
	else
		-- Recharge slowly
		amount = slow
	end

	-- If we have a staff
	if self.weapons.staff then
		-- Recharge it
		self.weapons.staff:add_ammo(amount)
	end

	if love.timer.getTime() > self.hurtTimer + 2 then
		-- Recharge health
		self:add_health(slow)
	end
end

function Character:set_current_weapon(num)
	for _,w in pairs(self.weapons) do
		if w.order == num then
			self.currentWeapon = w

			if instanceOf(Player, self) then
				sound.switchWeapon:play()
			end
			break
		end
	end
end

function Character:shoot(dir)
	-- Switch to a weapon that can shoot
	for _, w in pairs(self.weapons) do
		if w.projectileClass then
			self.currentWeapon = w
			break
		end
	end

	if (not self.currentWeapon or not self.currentWeapon.ammo or
	    self.dead) then
		return false
	end

	-- Check if we are trying to shoot into a brick
	for _,b in pairs(self.room.bricks) do
		if tiles_overlap(add_direction(self.position, dir), b) then
			-- Save ourself the ammo
			return false
		end
	end

	-- Try to create a new projectile
	newProjectile = self.currentWeapon:shoot(dir)

	-- If this weapon did not (or cannot) shoot
	if newProjectile == false then
		return false
	else
		self.room:add_object(newProjectile)
		return true
	end
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

function Character:update()
	if self.hurt then
		-- Flash if hurt
		self.flashTimer = 5
		self.hurt = false
	end

	-- Determine which image of this character to draw
	if (self.images.moving and
	    (self.path.nodes or self.moved or
	     self.action == Character.static.actions.flee)) then
		self.currentImage = self.images.moving
	elseif (self.images.sword and self.weapons.sword and
	        self.currentWeapon == self.weapons.sword) then
		self.currentImage = self.images.sword
	elseif (self.images.bow and self.weapons.bow and
	        self.currentWeapon == self.weapons.bow) then
		self.currentImage = self.images.bow
	elseif (self.images.staff and self.weapons.staff and
	        self.currentWeapon == self.weapons.staff) then
		self.currentImage = self.images.staff
	else
		self.currentImage = self.images.default
	end
end
