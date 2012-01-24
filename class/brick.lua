Brick = {}
Brick.__index = Brick

function Brick:new(x, y)
	local o = {}
	setmetatable(o, self)

	-- X and Y coordinates
	o.x = x
	o.y = y

	return o
end

function Brick:draw()
	love.graphics.setColor(255, 0, 255)
	love.graphics.rectangle('fill', self.x * TILE_W, self.y * TILE_H,
	                        TILE_W, TILE_H)
end
