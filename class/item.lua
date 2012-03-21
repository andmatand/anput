Item = class('Item')

function Item:init(position, itemType)
	self.position = position
	--self.position = {position.x, position.y}
	--print('item position table:', self.position)
	self.itemType = itemType

	if itemType == 1 then
		self.frames = {{image = arrowsImg}}
	elseif itemType == 2 then
		self.frames = {{image = potionImg}}
	elseif itemType == 3 then
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

	self.owner = nil
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

function Item:draw(alpha)
	local x, y
	x = (self.position.x * TILE_W)
	y = (self.position.y * TILE_H)

	self:animate()

	if self.frames ~= nil then
		love.graphics.setColor(255, 255, 255, alpha)
		love.graphics.draw(self.frames[self.currentFrame].image,
		                   x, y, 0, SCALE_X, SCALE_Y)
	elseif self.weapon ~= nil then
		love.graphics.setColor(255, 255, 255, alpha)
		self.weapon:draw(self.position)
	end
end

function Item:use()
	if self.owner then
		self:use_on(self.owner)
		self.owner:remove_from_inventory(self)
	end
end

function Item:use_on(patient)
	if self.itemType == 1 then
		-- Arrows
		-- If the patient has a bow
		if patient.weapons.bow then
			patient.weapons.bow:add_ammo(10)
			self.isUsed = true
			return true
		end
	elseif self.itemType == 2 then
		-- Health potion
		if paitent:add_health(10) then
			self.isUsed = true
			return true
		end
	end

	return false
end
