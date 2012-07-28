-- A Sprite is a physics object
Sprite = class('Sprite')

function Sprite:init()
    self.room = nil
    self.position = {x = nil, y = nil}
    self.oldPosition = self.position
    self.velocity = {x = 0, y = 0}
    self.friction = 1
    self.moved = false
    self.didPhysics = false

    -- Alias x and y for position
    --self.x = function() return self.position.x end
    --self.y = function() return self.position.y end
end

function Sprite:die()
    self.dead = true
end

function Sprite:get_position()
    return {x = self.position.x, y = self.position.y}
end

function Sprite:is_audible()
    return self.room:is_audible()
end

-- Preview what position the sprite will be at when its velocity is added
function Sprite:preview_position()
    if not self.position.x or not self.position.y then
        return {x = nil, y = nil}
    end

    -- Only one axis may have velocity at a time
    if self.velocity.x and self.velocity.x ~= 0 then
        return {x = self.position.x + self.velocity.x, y = self.position.y}
    elseif self.velocity.y and self.velocity.y ~= 0 then
        return {x = self.position.x, y = self.position.y + self.velocity.y}
    else
        return {x = self.position.x, y = self.position.y}
    end
end

-- Default hit method
function Sprite:hit(patient)
    if patient then
        if instanceOf(Projectile, patient) then
            -- Don't stop when hitting a projectile
            return false
        elseif patient:receive_hit(self) == false then
            -- Don't stop if the patient did not receive the hit
            return false
        end
    end

    -- Stop
    self.velocity.x = 0
    self.velocity.y = 0

    -- Valid hit
    return true
end

function Sprite:move_to_room(room)
    -- Remove ourself from our current room
    self.room:remove_object(self)

    -- Add ourself to the new room
    room:add_object(self)
end

function Sprite:physics()
    if self.didPhysics then
        return
    else
        self.didPhysics = true
    end

    self.oldPosition = {x = self.position.x, y = self.position.y}
    self.moved = false

    -- Do nothing if the sprite is not moving
    if self.velocity.x == 0 and self.velocity.y == 0 then
        if instanceOf(Monster, self) then
            -- Clear attackedDir
            self.attackedDir = nil
        end
        return
    end

    -- Make sure velocity does not contain nil values
    if not self.velocity.x then self.velocity.x = 0 end
    if not self.velocity.y then self.velocity.y = 0 end

    -- Create a test version of our position and room
    local test = {position = {x = self.position.x, y = self.position.y},
                  room = self.room}

    -- Restrict velocity to only one axis at a time (no diagonal moving)
    if self.velocity.x ~= 0 and self.velocity.y ~= 0 then
        self.velocity.y = 0
    end

    -- Compute test coordinates for potential new position
    test.position.x = test.position.x + self.velocity.x
    test.position.y = test.position.y + self.velocity.y
    
    -- Check for collision with bricks
    for i,b in pairs(test.room.bricks) do
        if tiles_overlap(test.position, b) then
            if self:hit(b) then
                -- Registered as a hit; done with physics
                return
            end
            break
        end
    end

    -- Check for collision with room edge
    --if test.position.x < 0 or test.position.x > ROOM_W - 1 or
    --   test.position.y < 0 or test.position.y > ROOM_H - 1 then
    --   if self:hit(nil) then
    --       return
    --   end
    --end

    -- Iterate through the room's exits
    for _, e in pairs(test.room.exits) do
        -- If we are going to hit this exit
        if tiles_overlap(test.position, e) then
            -- If we are a player
            if instanceOf(Player, self) then
                -- Generate the room if it hasn't already been generated
                if not e.room.isGenerated then
                    e.room:generate_all()
                end
            end

            -- If the room it leads to has been generated
            if e.room.isGenerated then
                local oldRoom = test.room

                -- Move test object to new room
                test.room = e.room

                -- Move the test coordinates to the doorway of the
                -- corresponding exit
                local newExit = test.room:get_exit({room = oldRoom})
                test.position = newExit:get_doorway()

                break
            else
                return
            end
        end
    end

    -- Check for collision with other sprites
    for i,s in pairs(test.room.sprites) do
        if s ~= self then
            if tiles_overlap(test.position, s.position) then
                -- If the other sprite hasn't done its physics yet
                if s.didPhysics == false and s.owner ~= self then
                    s.physics(s)
                end

                if self:hit(s) then
                    if test.room ~= self.room then
                        -- Sweep up in case we killed something
                        test.room:sweep()
                    end

                    -- Registered as a hit; done with physics
                    return
                end
            -- If the other sprite hasn't done physics yet, and we would have
            -- hit it if it had already
            elseif s.didPhysics == false and
                   tiles_overlap(test.position, s:preview_position()) then
                -- Allow us to move
                self.position = {x = test.position.x, y = test.position.y}
                if test.room ~= self.room then
                    self:move_to_room(test.room)
                end
                self.moved = true

                -- Do physics on the other sprite (will hit us)
                s.physics(s)

                -- Register a hit for us
                if self:hit(s) then
                    return
                end
            end
        end
    end

    -- Apply friction
    if self.velocity.x < 0 then
        self.velocity.x = self.velocity.x + self.friction
    elseif self.velocity.x > 0 then
        self.velocity.x = self.velocity.x - self.friction
    end
    if self.velocity.y < 0 then
        self.velocity.y = self.velocity.y + self.friction
    elseif self.velocity.y > 0 then
        self.velocity.y = self.velocity.y - self.friction
    end

    -- If there were no hits, make the move for real
    self.position = {x = test.position.x, y = test.position.y}
    if test.room ~= self.room then
        self:move_to_room(test.room)
    end
    self.moved = true
end

-- Default post-physics method
function Sprite:post_physics()
    self.didPhysics = false
end

function Sprite:receive_hit(agent)
    -- Register as a hit
    return true
end

function Sprite:set_position(position)
    self.position = {x = position.x, y = position.y}
end

function Sprite:update()
end

function Sprite:line_of_sight(patient)
    return self.room:line_of_sight(self.position, patient.position)
end

function Sprite:will_hit(patient)
    ok = false

    if self.velocity.y == -1 then
        -- Moving north
        if self.position.x == patient.position.x and
           (self.position.y == patient.position.y + 1 or
            (self.friction == 0 and self.position.y > patient.position.y)) then
            ok = true
        end
    end
    if self.velocity.y == 1 then
        -- Moving south
        if self.position.x == patient.position.x and
           (self.position.y == patient.position.y - 1 or
            (self.friction == 0 and self.position.y < patient.position.y)) then
            ok = true
        end
    end
    if self.velocity.x == -1 then
        -- Moving west
        if self.position.y == patient.position.y and
           (self.position.x == patient.position.x + 1 or
            (self.friction == 0 and self.position.x > patient.position.x)) then
            ok = true
        end
    end
    if self.velocity.x == 1 then -- Moving east
        if self.position.y == patient.position.y and
           (self.position.x == patient.position.x - 1 or
            (self.friction == 0 and self.position.x < patient.position.x)) then
            ok = true
        end
    end

    if ok and self:line_of_sight(patient) then
        return true
    else
        return false
    end
end
