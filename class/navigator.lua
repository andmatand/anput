require('class.pathfinder')

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

        local pf = PathFinder(src, d, self.hotLava, self.points,
                              {smooth = true})
        local points = pf:plot()

        for j, p in ipairs(points) do
            -- Exclude the source point (since it is the same as the previous
            -- destination) unless this is the first path
            if j > 1 or i == 1 then
                -- Add this point to the self.points
                table.insert(self.points, {x = p.x, y = p.y})
            end

            -- Add this point to hotlava
            --table.insert(self.hotLava, {x = p.x, y = p.y})
        end
    end

    return self.points
end
