Turret = class('Turret')

function Turret:init(position, dir, delay)
	self.position = {x = position.x, y = position.y}
	self.dir = dir
	self.delay = delay

	self.timer = 0
	self.room = nil
end

function Turret:update()
	if self.timer < self.delay then
		self.timer = self.timer + 1
		return
	end

	-- If we sense a character in front of us
	if self:sense() then
		self:shoot()

		-- Reset the delay timer
		self.timer = 0
	end
end

function Turret:sense()
	xDir = 0
	yDir = 0
	if self.dir == 1 then
		-- North
		yDir = -1
	elseif self.dir == 2 then
		-- East
		xDir = 1
	elseif self.dir == 3 then
		-- South
		yDir = 1
	elseif self.dir == 4 then
		-- West
		xDir = -1
	end

	x, y = self.position.x, self.position.y
	while true do
		x = x + xDir
		y = y + yDir

		contents = self.room:tile_contents({x = x, y = y})

		-- If we got to a tile outside the bounds of the room
		if contents == nil then
			return false
		end

		for _,c in pairs(contents) do
			if instanceOf(Character, c) then
				return true
			elseif instanceOf(Brick, c) then
				-- Encountered a brick or outside bounds of room
				return false
			end
		end
	end
end

function Turret:shoot()
	-- Create a new arrow in the right direction
	self.room:add_object(Arrow(self, self.dir))
end
