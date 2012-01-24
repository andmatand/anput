Turret = {}
Turret.__index = Turret

function Turret:new(dirs)
	local o = {}
	setmetatable(o, self)

	o.dirs = dirs -- Table of directions

	return o
end

function Turret:shoot()
	-- Loop through each direction for this turret
	for d in self.dirs do
		-- Create a new arrow in the right direction
		table.insert(game.arrows, Arrow:new(d))
	end
end
