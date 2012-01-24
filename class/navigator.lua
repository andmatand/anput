require 'class/pathfinder.lua'

Navigator = {}
Navigator.__index = Navigator

-- A Navigator plots a path with multiple destinations
function Navigator:new(srcX, srcY, destinations, hotLava)
	local o = {}
	setmetatable(o, self)

	o.srcX = srcX
	o.srcY = srcY
	o.destinations = destinations
	o.hotLava = hotLava -- Coordinates which are illegal to traverse
	if o.hotLava == nil then o.hotLava = {} end

	return o
end

function Navigator:plot()
	print('starting Navigator:plot()')
	self.points = {}

	for i,d in ipairs(self.destinations) do
		-- If this is the first destination
		if i == 1 then
			-- Source is initial source coordinates
			sX = self.srcX
			sY = self.srcY
		else
			-- Source is previous destination
			sX = destinations[i - 1].x
			sY = destinations[i - 1].y
		end

		pf = PathFinder:new(sX, sY, d.x, d.y, self.hotLava)
		points = pf:plot()

		for j,p in ipairs(points) do
			-- Add this point to the self.points
			table.insert(self.points, {x = p.x, y = p.y})

			-- Add this point to hotlava
			--table.insert(self.hotLava, {x = p.x, y = p.y})
		end
	end

	print('done with Navigator:plot()')
	return self.points
end
