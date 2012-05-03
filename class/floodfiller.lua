-- A FloodFiller finds all tiles accessible from x, y which are neither hotLava
-- nor outside the bounds of the room. Calling flood() returns a table of all
-- tiles reached.

FloodFiller = class('FloodFiller')

function FloodFiller:init(source, hotLava)
    self.source = source -- Needs to have and x and y key, e.g. {x = 2, y = 47}
    self.hotLava = hotLava -- Coordinates which are illegal to traverse
end

-- Implements a scanline flood-fill algorithm
function FloodFiller:flood()
    local seeds = {}
    local freeTiles = {}

    -- Add the source position as the first seed
    table.insert(seeds, self.source)

    while #seeds > 0 do
        -- Pop the last seed off the table
        seed = table.remove(seeds, #seeds)

        -- Find the top bound of this line
        local x = seed.x
        local y = seed.y
        while self:legal_position(x, y - 1) do
            y = y - 1
        end

        -- Start at the top and move down the line
        local searchLeft = true
        local searchRight = true
        while self:legal_position(x, y) do
            -- If this is not the source position
            if x ~= self.source.x or y ~= self.source.y then
                -- Add this tile to the table of found tiles
                table.insert(freeTiles, {x = x, y = y})
            end

            -- If our parent was not on the left side
            if not seed.parentOnLeft then
                -- If we are searching the left side and we find a legal
                -- position
                if searchLeft and self:legal_position(x - 1, y) then
                    -- Add a new seed at this position
                    table.insert(seeds, {x = x - 1, y = y,
                                         parentOnRight = true})
                    
                    -- Stop searching the left side for now
                    searchLeft = false

                -- If we are not searching the left side and we find an illegal
                -- position
                elseif (not searchLeft and
                        not self:legal_position(x - 1, y)) then
                    -- Start searching the left side again, since the old line
                    -- would not reach past here
                    searchLeft = true
                end
            end

            -- If our parent was not on the right side
            if not seed.parentOnRight then
                -- If we are searching the right side and we find a legal
                -- position
                if searchRight and self:legal_position(x + 1, y) then
                    -- Add a new seed at this position
                    table.insert(seeds, {x = x + 1, y = y,
                                         parentOnLeft = true})
                    
                    -- Stop searching the right side for now
                    searchRight = false
                -- If we are not searching the right side and we find an illegal
                -- position
                elseif (not searchRight and
                        not self:legal_position(x + 1, y)) then
                    -- Start searching the right side again, since the old line
                    -- would not reach past here
                    searchRight = true
                end
            end

            y = y + 1
        end
    end

    return freeTiles
end

function FloodFiller:legal_position(x, y)
    -- If this tile is outside the bounds of the room
    if x < 0 or x > ROOM_W - 1 or y < 0 or y > ROOM_H - 1 then
        return false
    end

    -- If this is an illegal tile
    if self.hotLava then
        for _, l in pairs(self.hotLava) do
            if x == l.x and y == l.y then
                return false
            end
        end
    end

    return true
end
