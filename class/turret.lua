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
    xDir = 0
    yDir = 0
    if self.dir == 1 then
        -- North
        yDir = -1
    elseif self.dir == 2 then
        -- East
        xDir = 1
    elseif self.dir == 3 then
        -- South
        yDir = 1
    elseif self.dir == 4 then
        -- West
        xDir = -1
    end

    local x, y
    x, y = self.position.x, self.position.y
    while true do
        x = x + xDir
        y = y + yDir

        -- If we got to a tile outside the room
        if not self.room:tile_in_room({x = x, y = y}) then
            return false
        end

        -- Check if we reached a brick
        for _, b in pairs(self.room.bricks) do
            if tiles_overlap({x = x, y = y}, b:get_position()) then
                return false
            end
        end

        -- Check if we reached a character
        for _, c in pairs(self.room:get_characters()) do
            if tiles_overlap({x = x, y = y}, c:get_position()) then
                return true
            end
        end

        --contents = self.room:tile_contents({x = x, y = y})

        ---- If we got to a tile outside the bounds of the room
        --if contents == nil then
        --    return false
        --end

        --for _,c in pairs(contents) do
        --    if instanceOf(Character, c) then
        --        return true
        --    elseif instanceOf(Brick, c) then
        --        -- Encountered a brick or outside bounds of room
        --        return false
        --    end
        --end
    end
end

function Turret:shoot()
    -- Create a new arrow in the right direction
    self.room:add_object(Arrow(self, self.dir))

    self:die()
end
