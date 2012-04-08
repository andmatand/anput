-- An Armory is a collection of Weapons
Armory = class('Armory')

function Armory:init(owner)
	self.owner = owner

	self.weapons = {}
	self.currentWeapon = nil
end

function Armory:add(weapon)
	local firstWeapon

	-- If we currently have no weapons
	if not next(self.weapons) then
		firstWeapon = true
	else
		firstWeapon = false
	end

	-- Add it to our weapons table, keyed by the weapon name
	self.weapons[weapon.name] = weapon
	weapon.owner = self.owner

	if firstWeapon then
		-- Set this new weapon as the current weapon
		self.currentWeapon = weapon
	end
end

function Armory:get_current_weapon_name()
	if self.currentWeapon then
		return self.currentWeapon.name
	else
		return nil
	end
end

function Armory:get_num_weapons()
	local num = 0
	for _, w in pairs(self.weapons) do
		num = num + 1
	end
	return num
end

function Armory:remove(weapon)
	-- If the weapon is in our weapons table
	if self.weapons[weapon.name] then
		-- If the weapon is our current weapon
		if weapon == self.currentWeapon then
			-- Clear our current weapon
			self.currentWeapon = nil
		end

		-- Remove the weapon from our weapons table
		self.weapons[weapon.name] = nil
	end
end

function Armory:set_current_weapon(weapon)
	-- If a weapon was given, and it's not the same as our current weapon
	if weapon and self.currentWeapon ~= weapon then
		-- If our owner is a player
		if instanceOf(Player, self.owner) then
			-- Play a cool sound
			sound.switchWeapon:play()
		end
	end

	-- Set the current weapon to the one given
	self.currentWeapon = weapon
end

function Armory:switch_to_next_weapon()
	local nextWeapon
	local lowest = 99
	for _, w in pairs(self.weapons) do
		-- If this weapon's order is higher than that of the current
		-- weapon and lower than the lowest one found
		if (w.order > self.currentWeapon.order and
		    w.order < lowest) then
			nextWeapon = w
			lowest = w.order
		end
	end

	-- If a next weapon was found
	if nextWeapon then
		self:set_current_weapon(nextWeapon)
	else
		-- Wrap around to the first item
		self:switch_to_weapon_number(1)
	end
end

-- Switches to the specified weapon number, numbering based on the order they
-- are displayed in the inventory display
function Armory:switch_to_weapon_number(number)
	local numWeapons = self:get_num_weapons()

	if number > numWeapons then
		return
	end

	for orderNum = number, number + numWeapons - 1 do
		-- Look for a weapon with the current orderNum
		for _, w in pairs(self.weapons) do
			if w.order == orderNum then
				self:set_current_weapon(w)
				return
			end
		end
	end
end
