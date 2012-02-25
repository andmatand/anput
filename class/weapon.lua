require('arrow')
require('fireball')

Weapon = class('Weapon')

-- Weapon templates
Weapon.static.templates = {
	sword = {name = 'sword', order = 1, damage = 15},
	bow = {name = 'bow', order = 2, ammo = 0, projectileClass = Arrow},
	staff = {name = 'staff', order = 3, ammo = 0, projectileClass = Fireball}
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

function Weapon:draw(position)
	if self.name == 'sword' then
		img = swordImg
	elseif self.name == 'bow' then
		img = bowImg
	elseif self.name == 'staff' then
		img = staffImg
	end

	love.graphics.draw(img,
					   position.x * TILE_W, position.y * TILE_H,
					   0, SCALE_X, SCALE_Y)
end

function Weapon:set_projectile_class(c)
	self.projectileClass = c
end

function Weapon:shoot(dir)
	if self.projectileClass == nil then
		return false
	else
		self.ammo = self.ammo - 1
		return self.projectileClass(self.owner, dir)
	end
end
