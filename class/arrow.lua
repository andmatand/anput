require('class/projectile')

Arrow = class('Arrow', Projectile)

function Arrow:init(owner, dir)
	Projectile.init(self, owner, dir)

	self.damage = 10
	self.images = projectileImg.arrow
end

function Arrow:hit(patient)
	-- Damage characters
	if instanceOf(Character, patient) then
		if patient:receive_hit(self) then
			patient:receive_damage(self.damage)
		else
			return false
		end
	end

	self:die()
	return true
end
