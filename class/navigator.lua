require('class.pathfinder')

-- A Navigator plots a path with multiple destinations
Navigator = class('Navigator')

function Navigator:init(source, destinations, lavaCache)
    self.source = source
    self.destinations = destinations
    self.lavaCache = lavaCache -- Coordinates which are illegal to traverse
end

function Navigator:plot()
    self.points = {}

    for i, d in ipairs(self.destinations) do
        local src

        -- If this is the first destination
        if i == 1 then
            -- Source is initial source coordinates
            src = self.source
        else
            -- Source is previous destination
            src = self.destinations[i - 1]
        end

        local pf = PathFinder(src, d, nil, self.points,
                              {smooth = true, lavaCache = self.lavaCache})
        local points = pf:plot()

        for j, p in ipairs(points) do
            -- Exclude the source point (since it is the same as the previous
            -- destination) unless this is the first path
            if j > 1 or i == 1 then
                -- Add this point to the self.points
                table.insert(self.points, {x = p.x, y = p.y})
            end
        end
    end

    return self.points
end
