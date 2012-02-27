Item = class('Item')

function Item:init(position, itemType)
	self.position = position
	self.itemType = itemType

	if itemType == 2 then
		self.image = potionImg
	else
		self.image = nil
	end

	self.used = false
end

function Item:draw()
	if self.itemType == 1 then
		-- Arrows
		love.graphics.setColor(WHITE)
	end

	x = (self.position.x * TILE_W)
	y = (self.position.y * TILE_H)

	if self.image ~= nil then
		love.graphics.setColor(WHITE)
		love.graphics.draw(self.image, x, y, 0, SCALE_X, SCALE_Y)
	elseif self.weapon ~= nil then
		love.graphics.setColor(WHITE)
		self.weapon:draw(self.position)
	else
		love.graphics.rectangle('fill',
		                        x + (TILE_W / 4),
		                        y + (TILE_H / 4),
		                        TILE_W / 2, TILE_H / 2)
	end
end

function Item:use_on(patient)
	if self.used then
		return false
	end

	if self.itemType == 1 then
		-- Arrows
		-- If the patient has a bow
		if patient.weapons.bow ~= nil then
			patient.weapons.bow:add_ammo(10)
			self.used = true

			-- Play sound depending on who picked it up
			if instanceOf(Player, patient) then
				sound.playerGetArrows:play()
			elseif instanceOf(Monster, patient) then
				sound.monsterGetArrows:play()
			end
		else
			return false
		end
	elseif self.itemType == 2 then
		-- Health potion
		if patient.health >= 100 then
			return false
		else
			patient.health = patient.health + 10
			if patient.health > 100 then
				patient.health = 100
			end

			self.used = true

			-- Play sound depending on who picked it up
			if instanceOf(Player, patient) then
				sound.playerGetHP:play()
			elseif instanceOf(Monster, patient) then
				sound.monsterGetHP:play()
			end
		end
	elseif self.itemType == 3 then
		-- Weapon
		patient:add_weapon(self.weapon)
		self.used = true

		sound.playerGetArrows:play()
	end
end
