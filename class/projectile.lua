require('sprite')

Projectile = class('Projectile', Sprite) 

function Projectile:init(owner, dir)
	Sprite.init(self)

	self.owner = owner -- Who shot this projectile
	self.dir = dir -- Direction the projectile is facing

	if self.dir == 1 then
		self.velocity.y = -1
	elseif self.dir == 2 then
		self.velocity.x = 1
	elseif self.dir == 3 then
		self.velocity.y = 1
	elseif self.dir == 4 then
		self.velocity.x = -1
	end

	self.friction = 0 -- Projectiles keep going until they hit something
	self.new = true -- Projectile was created this frame and will not be drawn
end

function Projectile:draw()
	if self.new then
		if self.moved then
			self.new = false
		end
		return
	end

	if self.image == nil then
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
	love.graphics.draw(self.image,
	                   (self.position.x * TILE_W) + self.image:getWidth(),
	                   (self.position.y * TILE_H) + self.image:getHeight(),
	                   r, sx, sy,
					   self.image:getWidth() / 2, self.image:getWidth() / 2)
end

function Projectile:physics()
	if self.new and self.owner ~= nil then
		-- Set position to current position of owner
		self.position = {x = self.owner.position.x, y = self.owner.position.y}
	end

	-- Do normal sprite physics
	Sprite.physics(self)
end
