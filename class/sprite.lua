-- A Sprite is a physics object
Sprite = class()

function Sprite:init()
	self.position = {x = nil, y = nil}
	self.velocity = {x = 0, y = 0}
end

function Sprite:move_to(coordinates)
	self.position.x = coordinates.x
	self.position.y = coordinates.y
end

function Sprite:physics(bricks, sprites)
	-- Test coordinates
	test = {x = self.position.x, y = self.position.y}

	-- Restrict velocity to only one axis at a time (no diagonal moving)
	if self.velocity.x ~= 0 and self.velocity.y ~= 0 then
		self.velocity.y = 0
	end

	test.x = test.x + self.velocity.x
	test.y = test.y + self.velocity.y
	
	for i,b in pairs(bricks) do
		if tiles_overlap(test, b) then
			if self:hit(b) then
				-- Registered as a hit; done with physics
				return
			end
			break
		end
	end

	-- If there were no hits, make the move for real
	self.position = test
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
