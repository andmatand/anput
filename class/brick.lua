Brick = class('Brick')

function Brick:init(coordinates)
	-- X and Y coordinates
	self.x = coordinates.x
	self.y = coordinates.y

	self.isCorporeal = true
end

function Brick:class_name()
	return 'Brick'
end

function Brick:draw(alpha)
	love.graphics.setColor(255, 0, 255, alpha)
	love.graphics.rectangle('fill', self.x * TILE_W, self.y * TILE_H,
	                        TILE_W, TILE_H)
end

function Brick:get_position()
	return {x = self.x, y = self.y}
end

function Brick:receive_hit(agent)
	-- Register as a hit
	return true
end

function Brick:set_position(position)
	self.x = position.x
	self.y = position.y
end
