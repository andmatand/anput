require 'class/sprite.lua'

Arrow = class(Sprite)

function Arrow:init(coordinates, dir)
	self.position = coordinates
	self.dir = dir -- Direction the arrow is facing

	if self.dir == 1 then
		self.velocity.y = -1
	elseif self.dir == 2 then
		self.velocity.x = 1
	elseif self.dir == 3 then
		self.velocity.y = 1
	elseif self.dir == 4 then
		self.velocity.x = -1
	end
end

function Arrow:class_name()
	return 'Arrow'
end

function Arrow:die()
	self.dead = true
end

function Arrow:draw()
	-- Determine the rotation amount
	if self.dir == 1 then 
		r = 0
	elseif self.dir == 2 then
		r = math.rad(90)
	elseif self.dir == 3 then
		r = math.rad(180)
	elseif self.dir == 4 then
		r = math.rad(270)
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(arrowImg,
	                   self.position.x * TILE_W,
	                   self.position.y * TILE_H,
	                   r, SCALE_X, SCALE_Y)
end

function Arrow:hit(patient)
	-- Die when we hit a brick
	if patient:class_name() == 'Brick' then
		self:die()
		return true
	end

	-- Damage players and monsters
	if patient:class_name() == 'Player' or patient:class() == 'Monster' then
		patient:receive_damage(10)
	end

	return false
end

function Arrow:post_physics()
end
