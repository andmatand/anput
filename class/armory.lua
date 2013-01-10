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

    -- Add it to our weapons table, keyed by the weapon type
    self.weapons[weapon.weaponType] = weapon
    weapon.owner = self.owner

    if firstWeapon then
        -- Set this new weapon as the current weapon
        self.currentWeapon = weapon
    end
end

function Armory:get_best_melee_weapon()
    local best = {meleeDamage = -1, weapon = nil}
    for _, w in pairs(self.weapons) do
        if w.meleeDamage then
            if w.meleeDamage > best.meleeDamage then
                best.meleeDamage = w.meleeDamage
                best.weapon = w
            end
        end
    end

    return best.weapon
end

function Armory:get_best_ranged_weapon()
    local best = {damage = -1, weapon = nil}
    for _, w in pairs(self.weapons) do
        if w.projectileClass then
            -- Create a test projectile of the sort that shoot forth from this
            -- weapon
            local projectile = w.projectileClass(self.owner)

            -- If this projectile's damage is better than the best, and
            -- it has enough ammo to shoot
            if projectile.damage > best.damage and
               w:get_ammo() > w.ammoCost then
                best.damage = projectile.damage
                best.weapon = w
            end
        end
    end

    return best.weapon
end

function Armory:get_current_weapon_type()
    if self.currentWeapon then
        return self.currentWeapon.weaponType
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
    if self.weapons[weapon.weaponType] then
        -- If the weapon is our current weapon
        if weapon == self.currentWeapon then
            -- Clear our current weapon
            self.currentWeapon = nil
        end

        -- Remove the weapon from our weapons table
        self.weapons[weapon.weaponType] = nil
    end
end

function Armory:set_current_weapon(weapon)
    -- If a weapon was given, and it's not the same as our current weapon
    if weapon and self.currentWeapon ~= weapon then
        -- If our owner is a player
        if instanceOf(Player, self.owner) then
            -- Play a cool sound
            sounds.menuSelect:play()
        end
    end

    -- Set the current weapon to the one given
    self.currentWeapon = weapon
end

function Armory:switch_to_melee_weapon()
    local w = self:get_best_melee_weapon()

    if w then
        self:set_current_weapon(w)
        return true
    else
        return false
    end
end

function Armory:switch_to_next_weapon()
    if not self.currentWeapon then
        self:switch_to_weapon_number(1)
    end

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

function Armory:switch_to_ranged_weapon()
    local w = self:get_best_ranged_weapon()

    if w then
        self:set_current_weapon(w)
        return true
    else
        return false
    end
end

-- Switches to the specified weapon number, numbering based on their intrinsic
-- order
function Armory:switch_to_weapon_number(number)
    local numWeapons = self:get_num_weapons()

    if number > numWeapons then
        return
    end

    local n = 0
    for order = 1, 9 do
        for _, w in pairs(self.weapons) do
            if w.order == order then
                n = n + 1
            end

            if n == number then
                self:set_current_weapon(w)
                return
            end
        end
    end
end
