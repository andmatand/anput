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

function Turret:update()
    -- If we sense a character in front of us
    if self:sense() then
        self:shoot()

        -- Reset the delay timer
        self.timer = 0
    end
end

function Turret:sense()
    -- Iterate through all the room's characters
    for _, c in pairs(self.room:get_characters()) do
        -- If there is a line of sight to this character
        if self.room:line_of_sight(self.position, c.position) then
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

function Turret:shoot()
    -- Create a new arrow in the right direction
    self.room:add_object(Arrow(self, self.dir))

    self:die()
end
