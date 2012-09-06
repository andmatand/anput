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
            sound.menuSelect:play()
        end

        -- Swap the new weapon and old currentWeapon in the inventory (so they
        -- don't jump around in the inventory menu)
        for i1, item1 in pairs(self.owner.inventory.items) do
            if item1 == self.currentWeapon then
                for i2, item2 in pairs(self.owner.inventory.items) do
                    if item2 == weapon then
                        self.owner.inventory.items[i1] = weapon
                        self.owner.inventory.items[i2] = self.currentWeapon
                        break
                    end
                end
                break
            end
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
