-- A Sprite is a physics object
Sprite = class('Sprite')

function Sprite:init()
	self.room = nil
	self.position = {x = nil, y = nil}
	self.oldPosition = self.position
	self.velocity = {x = 0, y = 0}
	self.friction = 1
	self.moved = false
	self.didPhysics = false

	-- Alias x and y for position
	--self.x = function() return self.position.x end
	--self.y = function() return self.position.y end
end

function Sprite:die()
	self.dead = true
end

-- Preview what position the sprite will be at when its velocity is added
function Sprite:preview_position()
	if self.position.x == nil or self.position.y == nil then
		return {x = nil, y = nil}
	end

	-- Only one axis may have velocity at a time
	if self.velocity.x ~= nil and self.velocity.x ~= 0 then
		return {x = self.position.x + self.velocity.x, y = self.position.y}
	elseif self.velocity.y ~= nil and self.velocity.y ~= 0 then
		return {x = self.position.x, y = self.position.y + self.velocity.y}
	else
		return {x = self.position.x, y = self.position.y}
	end
end

function Sprite:erase()
	if self.oldPosition.x == self.position.x and
	   self.oldPosition.y == self.position.y then
		self:draw()
	end
end

-- Default hit method
function Sprite:hit(patient)
	if patient ~= nil and instanceOf(Projectile, patient) then
		-- Don't stop when hitting a projectile
		return false
	elseif patient ~= nil and patient:receive_hit(self) == false then
		-- Don't stop if the patient did not receive the hit
		return false
	else
		-- Stop
		self.velocity.x = 0
		self.velocity.y = 0
	end

	-- Valid hit
	return true
end

function Sprite:move_to(coordinates)
	self.position.x = coordinates.x
	self.position.y = coordinates.y
end

function Sprite:physics()
	if self.didPhysics then
		return
	else
		self.didPhysics = true
	end

	self.oldPosition = {x = self.position.x, y = self.position.y}
	self.moved = false

	-- Do nothing if the sprite is not moving
	if self.velocity.x == 0 and self.velocity.y == 0 then
		-- Clear attackedDir
		--self.attackedDir = nil
		return
	end

	-- Make sure velocity does not contain nil values
	if self.velocity.x == nil then self.velocity.x = 0 end
	if self.velocity.y == nil then self.velocity.y = 0 end

	-- Test coordinates
	self.test = {x = self.position.x, y = self.position.y}

	-- Restrict velocity to only one axis at a time (no diagonal moving)
	if self.velocity.x ~= 0 and self.velocity.y ~= 0 then
		self.velocity.y = 0
	end

	-- Compute test coordinates for potential new position
	self.test.x = self.test.x + self.velocity.x
	self.test.y = self.test.y + self.velocity.y

	-- Apply friction
	if self.velocity.x < 0 then
		self.velocity.x = self.velocity.x + self.friction
	elseif self.velocity.x > 0 then
		self.velocity.x = self.velocity.x - self.friction
	end
	if self.velocity.y < 0 then
		self.velocity.y = self.velocity.y + self.friction
	elseif self.velocity.y > 0 then
		self.velocity.y = self.velocity.y - self.friction
	end
	
	-- Check for collision with bricks
	for i,b in pairs(self.room.bricks) do
		if tiles_overlap(self.test, b) then
			if self:hit(b) then
				-- Registered as a hit; done with physics
				return
			end
			break
		end
	end

	-- Check for collision with room edge
	if self.test.x < 0 or self.test.x > ROOM_W - 1 or
	   self.test.y < 0 or self.test.y > ROOM_H - 1 then
	   if self:hit(nil) then
		   return
	   end
	end

	-- Check for collision with other sprites
	for i,s in pairs(self.room.sprites) do
		if s ~= self then
			if tiles_overlap(self.test, s.position) then
				-- If the other sprite hasn't done its physics yet
				if s.didPhysics == false and s.owner ~= self then
					s.physics(s)
				end

				if self:hit(s) then
					-- Registered as a hit; done with physics
					return
				end
			-- If the other sprite hasn't done physics yet, and we would have
			-- hit it if it had already
			elseif s.didPhysics == false and
			       tiles_overlap(self.test, s:preview_position()) then
				-- Allow us to move
				self.position = {x = self.test.x, y = self.test.y}
				self.moved = true

				-- Do physics on the other sprite (will hit us)
				s.physics(s)

				-- Register a hit for us
				if self:hit(s) then
					return
				end
			end
		end
	end

	-- If this is a character
	if instanceOf(Character, self) then
		-- Check for overlap with items
		for _,i in pairs(self.room.items) do
			if tiles_overlap(self.test, i.position) then
				i:use_on(self)
			end
		end
	end

	-- If there were no hits, make the move for real
	self.position = {x = self.test.x, y = self.test.y}
	self.moved = true
end

-- Default post-physics method
function Sprite:post_physics()
	self.didPhysics = false
end

function Sprite:receive_hit(agent)
	-- Register as a hit
	return true
end

function Sprite:line_of_sight(patient)
	return self.room:line_of_sight(self.position, patient.position)
end

function Sprite:will_hit(patient)
	ok = false

	if self.velocity.y == -1 then
		-- Moving north
		if self.position.x == patient.position.x and
		   (self.position.y == patient.position.y + 1 or
		    (self.friction == 0 and self.position.y > patient.position.y)) then
			ok = true
		end
	end
	if self.velocity.y == 1 then
		-- Moving south
		if self.position.x == patient.position.x and
		   (self.position.y == patient.position.y - 1 or
		    (self.friction == 0 and self.position.y < patient.position.y)) then
			ok = true
		end
	end
	if self.velocity.x == -1 then
		-- Moving west
		if self.position.y == patient.position.y and
		   (self.position.x == patient.position.x + 1 or
		    (self.friction == 0 and self.position.x > patient.position.x)) then
			ok = true
		end
	end
	if self.velocity.x == 1 then -- Moving east
		if self.position.y == patient.position.y and
		   (self.position.x == patient.position.x - 1 or
		    (self.friction == 0 and self.position.x < patient.position.x)) then
			ok = true
		end
	end

	if ok and self:line_of_sight(patient) then
		return true
	else
		return false
	end
end
