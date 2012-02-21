require('projectile')

Arrow = class('Arrow', Projectile)

function Arrow:init(owner, dir)
	Projectile.init(self, owner, dir)

	self.images = projectileImg.arrow
end

function Arrow:hit(patient)
	-- Damage characters
	if instanceOf(Character, patient) then
		if patient:receive_hit(self) then
			patient:receive_damage(10)
		else
			return false
		end
	end

	self:die()
	return true
end
