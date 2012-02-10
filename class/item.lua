Item = class('Item')

function Item:init(position, itemType)
	self.position = {x = position.x, y = position.y}
	self.itemType = itemType

	self.used = false
end

function Item:draw()
	if self.itemType == 1 then
		-- Arrows
		love.graphics.setColor(255, 255, 255)
	elseif self.itemType == 2 then
		-- Health potion
		love.graphics.setColor(255, 85, 85)
	end

	love.graphics.rectangle('fill',
	                        (self.position.x * TILE_W) + (TILE_W / 4),
							(self.position.y * TILE_H) + (TILE_H / 4),
	                        TILE_W / 2, TILE_H / 2)
end

function Item:use_on(patient)
	if self.used then
		return false
	end

	if self.itemType == 1 then
		-- Arrows
		patient.arrows.ammo = patient.arrows.ammo + 10
		self.used = true
	elseif self.itemType == 2 then
		-- Health potion
		if patient.health >= 100 then
			return false
		else
			patient.health = patient.health + 10
			self.used = true
		end
	end
end
