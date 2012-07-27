require('util.tile')

function shootable_directions(position, freeTiles)
    -- This is the minimum number of free tiles which must exist in front of
    -- the source position in a direction for it to be considered valid
    local minDistance = 3

    local dirs = {}

    for dir = 1,4 do
        -- Move in this direction and check each tile
        local pos = position
        for dist = 1,minDistance do
            pos = add_direction(pos, dir)

            if not tile_in_table(pos, freeTiles) then
                break

            -- If we reached the minimum distance
            elseif dist == minDistance then
                table.insert(dirs, dir)
            end
        end
    end

    return dirs
end 

Turret = class('Turret')

function Turret:init(position, dir)
    self.position = {x = position.x, y = position.y}
    self.dir = dir

    self.room = nil
end

function Turret:die()
    self.dead = true
end

function Turret:find_max_distance()
    local pos = copy_table(self.position)
    local dist = 0
    while true do
        pos = add_direction(pos, self.dir)

        -- If we encountered a brick, or the edge of the screen
        if tile_in_table(pos, self.room.bricks) or tile_offscreen(pos) then
            -- This is our maximum sensing distance
            self.maxDistance = dist
            return
        else
            dist = dist + 1
        end
    end
end

function Turret:update()
    if self.room then
        -- If we haven't determined our maximum look-ahead distance yet
        if not self.maxDistance then
            self:find_max_distance()
        end

        -- If we sense a character in front of us
        if self:sense() then
            self:shoot()
        end
    end
end

function Turret:sense()
    -- Iterate through all the room's characters
    for _, c in pairs(self.room:get_characters()) do
        -- If this character is corporeal, and there is a line of sight to him
        if c.isCorporeal and self:line_of_sight(c.position) then
            -- If this room hasn't played the trap sound yet, and we are
            -- targeting a player
            if not self.room.playedTrapSound and instanceOf(Player, c) then
                -- Play the trap sound
                self.room.playedTrapSound = true
                sound.trap:play()
            end
            return true
        end
    end

    return false
end

-- Returns true if we have a line of sight to the given target position.
-- This function is more optimized for turrets than the function of the same
-- name in the Room class.
function Turret:line_of_sight(target)
    -- If we are pointing north or south
    if self.dir == 1 or self.dir == 3 then
        -- If the target is not aligned with us on the x-axis
        if target.x ~= self.position.x then
            return false
        end
    -- If we are pointing east or west
    elseif self.dir == 2 or self.dir == 4 then
        -- If the target is not aligned with us on the x-axis
        if target.y ~= self.position.y then
            return false
        end
    end

    -- North
    if self.dir == 1 then
        if (target.y >= self.position.y or
            target.y < self.position.y - self.maxDistance) then
            return false
        end
    -- East
    elseif self.dir == 2 then
        if (target.x <= self.position.x or
            target.x > self.position.x + self.maxDistance) then
            return false
        end
    -- South
    elseif self.dir == 3 then
        if (target.y <= self.position.y or
            target.y > self.position.y + self.maxDistance) then
            return false
        end
    -- West
    elseif self.dir == 4 then
        if (target.x >= self.position.x or
            target.x < self.position.x - self.maxDistance) then
            return false
        end
    end

    -- If none of the exluding circumstances above have applied, there must be
    -- a line of sight
    return true
end

function Turret:shoot()
    -- Create a new arrow in the right direction
    self.room:add_object(Arrow(self, self.dir))

    self:die()
end
