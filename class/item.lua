Item = class('Item')

function Item:init(position, itemType)
	self.position = position
	self.itemType = itemType

	if itemType == 1 then
		self.frames = {{image = arrowsImg}}
	elseif itemType == 2 then
		self.frames = {{image = potionImg}}
	elseif itemType == 4 then
		self.frames = {
			{image = shinyThingImg[1], delay = 30},
			{image = shinyThingImg[2], delay = 8},
			{image = shinyThingImg[3], delay = 8},
			{image = shinyThingImg[2], delay = 8},
			{image = shinyThingImg[3], delay = 8}}
	else
		self.frames = nil
	end

	self.currentFrame = 1
	self.animateTimer = 0
	self.animationEnabled = true

	self.used = false
end

function Item:animate()
	-- If there's nothing to animate
	if (self.frames == nil or #self.frames < 2 or
	    self.animationEnabled == false) then
		-- Go away
		return
	end

	self.animateTimer = self.animateTimer + 1

	if self.animateTimer >= self.frames[self.currentFrame].delay then
		self.animateTimer = 0
		self.currentFrame = self.currentFrame + 1

		-- Loop back around to the first frame
		if self.currentFrame > #self.frames then
			self.currentFrame = 1
		end
	end
end

function Item:draw()
	if self.itemType == 1 then
		-- Arrows
		love.graphics.setColor(WHITE)
	end

	local x, y
	x = (self.position.x * TILE_W)
	y = (self.position.y * TILE_H)

	self:animate()

	if self.frames ~= nil then
		love.graphics.setColor(WHITE)
		love.graphics.draw(self.frames[self.currentFrame].image,
		                   x, y, 0, SCALE_X, SCALE_Y)
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
	elseif self.itemType == 4 then
		-- Shiny thing
		patient:add_to_inventory(self)
		self.used = true
	end
end
