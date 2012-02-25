require('arrow')
require('fireball')

Weapon = class('Weapon')

-- Weapon templates
Weapon.static.templates = {
	sword = {ammo = nil, projectileClass = nil},
	bow = {ammo = 0,
	       projectileClass = Arrow},
	staff = {ammo = 0,
	         projectileClass = Fireball}
	}

function Weapon:init(owner, weaponType)
	self.owner = owner

	-- Copy the weapon template for the specified type to create a new weapon
	for k,v in pairs(Weapon.static.templates[weaponType]) do
		self[k] = v
	end
end

function Weapon:add_ammo(amount)
	self.ammo = self.ammo + amount
end

function Weapon:shoot(dir)
	if self.projectileClass == nil then
		return false
	else
		self.ammo = self.ammo - 1
		return self.projectileClass(self.owner, dir)
	end
end

function Weapon:set_projectile_class(c)
	self.projectileClass = c
end
