require 'class/pathfinder.lua'

Navigator = {}
Navigator.__index = Navigator

-- A Navigator plots a path with multiple destinations
function Navigator:new(source, destinations, hotLava)
	local o = {}
	setmetatable(o, self)

	o.source = source
	o.destinations = destinations
	o.hotLava = hotLava -- Coordinates which are illegal to traverse
	if o.hotLava == nil then o.hotLava = {} end

	return o
end

function Navigator:plot()
	self.points = {}

	for i,d in ipairs(self.destinations) do
		-- If this is the first destination
		if i == 1 then
			-- Source is initial source coordinates
			src = self.source
		else
			-- Source is previous destination
			src = destinations[i - 1]
		end

		pf = PathFinder:new(src, d, self.hotLava, self.points, {smooth = true})
		points = pf:plot()

		for j,p in ipairs(points) do
			-- Add this point to the self.points
			table.insert(self.points, {x = p.x, y = p.y})

			-- Add this point to hotlava
			--table.insert(self.hotLava, {x = p.x, y = p.y})
		end
	end

	return self.points
end
