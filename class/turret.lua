Turret = class('Turret')

function Turret:init(position, dir, interval)
	self.position = position
	self.dir = dir -- Table of directions
	self.interval = interval

	self.timer = self.interval
	self.room = nil
end

function Turret:update()
	self.timer = self.timer - 1
	if self.timer <= 0 then
		self:shoot()
		self.timer = self.interval
	end
end

function Turret:shoot()
	-- Create a new arrow in the right direction
	self.room:add_sprite(Arrow(self, self.dir))
	print('turret: pew!')
end
