require 'class/sprite.lua'

Arrow = class('Arrow', Sprite)

function Arrow:init(owner, dir)
	Sprite.init(self)

	self.owner = owner -- Who shot this arrow
	self.dir = dir -- Direction the arrow is facing

	--self.position = {x = self.owner.position.x, y = self.owner.position.y}

	if self.dir == 1 then
		self.velocity.y = -1
	elseif self.dir == 2 then
		self.velocity.x = 1
	elseif self.dir == 3 then
		self.velocity.y = 1
	elseif self.dir == 4 then
		self.velocity.x = -1
	end

	self.friction = 0 -- Arrows keep going until they hit something
	self.new = true -- Arrow was created this frame and will not be drawn
end

function Arrow:die()
	self.dead = true
end

function Arrow:draw()
	if self.new then
		if self.moved then
			self.new = false
		end
		return
	end

	-- Determine the rotation/flipping
	r = 0
	sx = SCALE_X
	sy = SCALE_Y
	if self.dir == 2 then
		r = math.rad(90)
	elseif self.dir == 3 then
		sy = -SCALE_Y
	elseif self.dir == 4 then
		r = math.rad(90)
		sy = -SCALE_Y
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(arrowImg,
	                   (self.position.x * TILE_W) + arrowImg:getWidth(),
	                   (self.position.y * TILE_H) + arrowImg:getHeight(),
	                   r, sx, sy,
					   arrowImg:getWidth() / 2, arrowImg:getWidth() / 2)
end

function Arrow:hit(patient)
	self:die()

	-- Damage characters
	if instanceOf(Character, patient) then
		patient:receive_damage(10)
	end

	return true
end

function Arrow:physics()
	if self.new and self.owner ~= nil then
		-- Set position to current position of owner
		self.position = {x = self.owner.position.x, y = self.owner.position.y}
	end

	-- Do normal sprite physics
	Sprite.physics(self)
end
