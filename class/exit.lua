Exit = class('Exit')

function Exit:init(args)
    self.x = args.x
    self.y = args.y
    self.room = args.room -- The room in which this exit is

    self.targetRoom = nil -- The room to which this exit leads
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

    return {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
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

function Exit:get_position()
    return {x = self.x, y = self.y}
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

function Exit:is_hidden()
    if not self.room or not self.room.bricks then
        return false
    end

    -- Check if there is a false brick in our doorway
    for _, b in pairs(self.room.bricks) do
        if instanceOf(FalseBrick, b) and
           tiles_overlap(b:get_position(), self:get_doorway()) then
            return true
        end
    end

    return false
end
