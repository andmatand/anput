-- A Sprite is a physics object
Sprite = class()

function Sprite:move_to(coordinates)
	self.x = coordinates.x
	self.y = coordinates.y
end

--o.x = nil
--o.y = nil
--o.xVel = nil -- x velocity
--o.yVel = nil -- y velocity
