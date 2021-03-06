Exit = class('Exit')

function Exit:init(args)
    self.x = args.x
    self.y = args.y
    self.room = args.room -- The room in which this exit is

    self.targetRoom = nil -- The room to which this exit leads
end

function Exit:get_direction()
    if self.y == -1 then
        return 1 -- North
    elseif self.x == ROOM_W then
        return 2 -- East
    elseif self.y == ROOM_H then
        return 3 -- South
    elseif self.x == -1 then
        return 4 -- West
    end
end

function Exit:get_doorframes()
    local x1, y1, x2, y2

    if self.y == -1 then
        -- North
        x1 = self.x - 1
        y1 = self.y + 1
        x2 = self.x + 1
        y2 = y1
    elseif self.x == ROOM_W then
        -- East
        x1 = self.x - 1
        y1 = self.y - 1
        x2 = x1
        y2 = self.y + 1
    elseif self.y == ROOM_H then
        -- South
        x1 = self.x + 1
        y1 = self.y - 1
        x2 = self.x - 1
        y2 = y1
    elseif self.x == -1 then
        -- West
        x1 = self.x + 1
        y1 = self.y + 1
        x2 = x1
        y2 = self.y - 1
    end

    return {{x = x1, y = y1}, {x = x2, y = y2}}
end

function Exit:get_doorway()
    local x, y
    local dir = self:get_direction()

    if dir == 1 then
        -- North
        x = self.x
        y = self.y + 1
    elseif dir == 2 then
        -- East
        x = self.x - 1
        y = self.y
    elseif dir == 3 then
        -- South
        x = self.x
        y = self.y - 1
    elseif dir == 4 then
        -- West
        x = self.x + 1
        y = self.y
    end

    return {x = x, y = y}
end

function Exit:get_linked_exit()
    for _, e in pairs(self.targetRoom.exits) do
        if e.targetRoom == self.room then
            return e
        end
    end
end

function Exit:get_position()
    return {x = self.x, y = self.y}
end

function Exit:is_collidable()
    if self:is_hidden() then
        return true
    else
        -- Check if a collidable character is standing in (blocking) the
        -- doorway to which we lead
        local destination = self:get_linked_exit():get_doorway()
        for _, c in pairs(self:get_linked_exit().room:get_characters()) do
            if tiles_overlap(c:get_position(), destination) then
                if c:is_collidable() then
                    return true
                end
            end
        end
    end

    return false
end

function Exit:is_hidden()
    if not self.room then
        return false
    end

    -- Check if there is a false brick in our doorway
    for _, b in pairs(self.room.bricks) do
        if instanceOf(FalseBrick, b) and
           tiles_overlap(b:get_position(), self:get_doorway()) then
            return true
        end
    end

    -- If there is a non-open door in our doorway
    local door = self:get_door()
    if door and door.state ~= 'open' then
        return true
    end

    return false
end

function Exit:get_door()
    local tile = self.room.tileCache:get_tile(self:get_doorway())
    for _, obj in pairs(tile.contents) do
        if instanceOf(Door, obj) then
            return obj
        end
    end
end
