require('pathfinder')

-- A Navigator plots a path with multiple destinations
Navigator = class('Navigator')

function Navigator:init(source, destinations, hotLava)
	self.source = source
	self.destinations = destinations
	self.hotLava = hotLava -- Coordinates which are illegal to traverse
	if self.hotLava == nil then self.hotLava = {} end
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

		pf = PathFinder(src, d, self.hotLava, self.points, {smooth = true})
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
