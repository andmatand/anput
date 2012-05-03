require('class/projectile')

Fireball = class('Fireball', Projectile)

function Fireball:init(owner, dir)
    Projectile.init(self, owner, dir)

    self.damage = 20
    self.images = projectileImg.fireball
end

function Fireball:hit(patient)
    -- Damage characters
    if instanceOf(Character, patient) and patient:receive_hit(self) then
        patient:receive_damage(self.damage)
    end

    -- Only stop when we hit a wall or go out of bounds
    if instanceOf(Brick, patient) or patient == nil then
        self:die()
        return true
    end

    return false
end
