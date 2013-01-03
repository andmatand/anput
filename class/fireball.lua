require('class.projectile')

Fireball = class('Fireball', Projectile)

function Fireball:init(owner, dir)
    Projectile.init(self, owner, dir)

    self.damage = 20
    self.images = projectileImg.fireball
    self.isMagic = true
end

function Fireball:hit(patient)
    -- Damage characters
    if instanceOf(Character, patient) and patient:receive_hit(self) then
        patient:receive_damage(self.damage, self)
    end

    -- Only stop when we hit a brick or a door or we go out of bounds
    if instanceOf(Brick, patient) or instanceOf(Door, patient) or
       patient == nil then
        self:die()
        return true
    end

    return false
end
