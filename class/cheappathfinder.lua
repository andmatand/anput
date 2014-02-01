CheapPathFinder = class("CheapPathFinder")

function CheapPathFinder:init(src, dest, bounds, prng)
    self.src = src
    self.dest = dest
    self.bounds = bounds
    self.prng = prng
end

function CheapPathFinder:plot()
    local nodes = {}
    local pos = {x = self.src.x, y = self.src.y}

    -- Add the self.src position
    table.insert(nodes, {x = pos.x, y = pos.y})

    repeat
        local moveX = false
        local moveY = false

        if pos.x ~= self.dest.x and (self.prng:random(0, 1) == 0 or
                                     pos.y == self.dest.y) then
            moveX = true
        else
            moveY = true
        end

        if self.bounds then
            -- If we are on the border of our bounds, move in
            if pos.x == self.bounds.x1 or pos.x == self.bounds.x2 then
                moveX = true
                moveY = false
            elseif pos.y == self.bounds.y1 or pos.y == self.bounds.y2 then
                moveX = false
                moveY = true
            end
        end

        if moveX then
            if pos.x < self.dest.x then
                pos.x = pos.x + 1
            elseif pos.x > self.dest.x then
                pos.x = pos.x - 1
            end
        elseif moveY then
            if pos.y < self.dest.y then
                pos.y = pos.y + 1
            elseif pos.y > self.dest.y then
                pos.y = pos.y - 1
            end
        end

        -- Add the current position
        table.insert(nodes, {x = pos.x, y = pos.y})
    until tiles_overlap(pos, self.dest)

    return nodes
end
