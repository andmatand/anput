require('class/arrow')
require('class/fireball')

-- A weapon is an Item that can also hurt other Characters or shoot Projectiles
Weapon = class('Weapon', Item)

-- Weapon templates
Weapon.static.templates = {
    sword = {name = 'sword', order = 1, damage = 15},
    bow = {name = 'bow', order = 2, ammo = 0, cost = 1,
           projectileClass = Arrow},
    staff = {name = 'staff', order = 3, ammo = 100, maxAmmo = 100, cost = 10,
             projectileClass = Fireball}
    }

function Weapon:init(weaponType)
    Weapon.super.init(self, weaponType)

    -- Copy the weapon template for the specified type to create a new weapon
    for k, v in pairs(Weapon.static.templates[weaponType]) do
        self[k] = v
    end
end

function Weapon:add_ammo(amount)
    self.ammo = self.ammo + amount

    if self.maxAmmo ~= nil then
        if self.ammo > self.maxAmmo then
            self.ammo = self.maxAmmo
        end
    end
end

function Weapon:draw(position)
    position = position or self.position

    if self.name == 'sword' then
        img = swordImg
    elseif self.name == 'bow' then
        img = bowImg
    elseif self.name == 'staff' then
        img = staffImg
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img,
                       upscale_x(position.x), upscale_y(position.y),
                       0, SCALE_X, SCALE_Y)
end

function Weapon:set_projectile_class(c)
    self.projectileClass = c
end

function Weapon:set_cost(cost)
    self.cost = cost
end

function Weapon:shoot(dir)
    if self.projectileClass == nil then
        return false
    else
        if self.ammo >= self.cost then
            self.ammo = self.ammo - self.cost
            return self.projectileClass(self.owner, dir)
        else
            sound.noAmmo:play()
            return false
        end
    end
end
