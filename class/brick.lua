Brick = class('Brick')

function Brick:init(coordinates)
	-- X and Y coordinates
	self.x = coordinates.x
	self.y = coordinates.y
end

function Brick:class_name()
	return 'Brick'
end

function Brick:draw()
	love.graphics.setColor(255, 0, 255)
	love.graphics.rectangle('fill', self.x * TILE_W, self.y * TILE_H,
	                        TILE_W, TILE_H)
end

function Brick:receive_hit(agent)
	-- Register as a hit
	return true
end
