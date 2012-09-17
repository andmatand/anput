require('class.projectile')

Arrow = class('Arrow', Projectile)

function Arrow:init(owner, dir)
    Projectile.init(self, owner, dir)

    self.damage = 10
    self.images = projectileImg.arrow
    self.playedSound = false
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

function Arrow:update()
    if not self.playedSound then
        if self:is_audible() then
            sounds.shootArrow:play()
        end

        self.playedSound = true
    end
end
