require('class/projectile')

Arrow = class('Arrow', Projectile)

function Arrow:init(owner, dir)
    Projectile.init(self, owner, dir)

    self.damage = 10
    self.images = projectileImg.arrow
end

function Arrow:hit(patient)
    if patient:receive_hit(self) then
        -- If we hit a character
        if instanceOf(Character, patient) then
            -- Damage the character
            patient:receive_damage(self.damage, self)
        end

        -- Die when we hit anything
        self:die()

        return true
    else
        return false
    end
end
