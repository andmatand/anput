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

	test.x = test.x + self.velocity.x
	test.y = test.y + self.velocity.y
	
	for i,b in pairs(bricks) do
		if tiles_overlap(test, b) then
			if self:receive_hit(b) == false then
				return
			end
			break
		end
	end

	-- If there were no hits, make the move for real
	self.position = test
end

function Sprite:post_physics()
	-- Sprites lose momentum after moving one tile
	self.velocity.x = 0
	self.velocity.y = 0
end

function Sprite:receive_hit(agent)
	if agent:class_name() == 'Brick' then
		self.velocity.x = 0
		self.velocity.y = 0
	end
	return false
end

--o.x = nil
--o.y = nil
--o.xVel = nil -- x velocity
--o.yVel = nil -- y velocity
