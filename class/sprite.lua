-- A Sprite is a physics object
Sprite = class()

function Sprite:init()
	self.position = {x = nil, y = nil}
	self.velocity = {x = 0, y = 0}
	self.moved = false
end

-- Preview what position the sprite would be at if a velocity was added
function Sprite:preview_velocity(position, velocity)
	-- Only one axis may have velocity at a time
	if velocity.x ~= nil then
		return {x = position.x + velocity.x, y = position.y}
	elseif velocity.y ~= nil then
		return {x = position.x, y = position.y + velocity.y}
	else
		return {x = position.x, y = position.y}
	end
end

function Sprite:erase()
	if self.oldPosition.x == self.position.x and
	   self.oldPosition.y == self.position.y then
		self:draw()
	end
end

function Sprite:move_to(coordinates)
	self.position.x = coordinates.x
	self.position.y = coordinates.y
end

function Sprite:physics(bricks, sprites)
	self.oldPosition = {x = self.position.x, y = self.position.y}
	self.moved = false

	-- Do nothing if the sprite is not moving
	if self.velocity.x == 0 and self.velocity.y == 0 then
		return
	end

	-- Make sure velocity does not contain nil values
	if self.velocity.x == nil then self.velocity.x = 0 end
	if self.velocity.y == nil then self.velocity.y = 0 end

	-- Test coordinates
	test = {x = self.position.x, y = self.position.y}

	-- Restrict velocity to only one axis at a time (no diagonal moving)
	if self.velocity.x ~= 0 and self.velocity.y ~= 0 then
		self.velocity.y = 0
	end

	test.x = test.x + self.velocity.x
	test.y = test.y + self.velocity.y
	
	-- Check for collision with bricks
	for i,b in pairs(bricks) do
		if tiles_overlap(test, b) then
			if self:hit(b) then
				-- Registered as a hit; done with physics
				return
			end
			break
		end
	end

	-- Check for collision with room edge
	if test.x < 0 or test.x > ROOM_W - 1 or
	   test.y < 0 or test.y > ROOM_H - 1 then
	   if self:hit(nil) then
		   return
	   end
	end

	-- Check for collision with other sprites
	for i,s in pairs(sprites) do
		if s ~= self and tiles_overlap(test, s.position) then
			if self:hit(s) then
				-- Registered as a hit; done with physics
				return
			end
			break
		end
	end

	-- If there were no hits, make the move for real
	self.position = test
	self.moved = true
end

-- Default post-physics method
function Sprite:post_physics()
	-- Lose momentum after moving one tile
	self.velocity.x = 0
	self.velocity.y = 0
end

-- Default hit method
function Sprite:hit(patient)
	-- Stop when we hit a brick
	if patient:class_name() == 'Brick' then
		self.velocity.x = 0
		self.velocity.y = 0

		-- Valid hit
		return true
	end

	-- Ignore this hit
	return false
end
