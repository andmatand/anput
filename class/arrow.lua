Arrow = {}
Arrow.__index = Arrow

function Arrow:new(dir)
	local o = {}
	setmetatable(o, self)

	o.dir = dir -- Direction

	return o
end

function Arrow:draw()
	-- Determine the rotation amount
	if self.dir == 0 then 
		r = 0
	elseif self.dir == 1 then
		r = math.rad(90)
	elseif self.dir == 2 then
		r = math.rad(180)
	elseif self.dir == 3 then
		r = math.rad(270)
	end

	love.graphics.draw(arrowImage, self.x, self.y, r, TILE_W, TILE_H)
end

--function Arrow:new (o, game)
--	o = o or {}   -- Create object if user does not provide one
--	setmetatable(o, self)
--	self.__index = self
--
--	return o
--end
