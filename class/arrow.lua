require 'class/sprite.lua'

Arrow = class('Arrow', Sprite)

function Arrow:init(coordinates, dir)
	Sprite.init(self)

	self.position = coordinates
	self.oldPosition = coordinates
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
	                   (self.position.x * TILE_W) + arrowImg:getWidth(),
	                   (self.position.y * TILE_H) + arrowImg:getHeight(),
	                   r,
	                   SCALE_X, SCALE_Y,
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
