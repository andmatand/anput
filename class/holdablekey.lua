-- A HoldableKey keeps track of the state of virtual a key used by the game
-- which may be pressed and held by either a keyboard or a joystick
HoldableKey = class('HoldableKey')

function HoldableKey:init()
    -- Key states:
    --   0 not pressed
    --   1 pressed initially
    --   2 held
    self.state = 0
end

function HoldableKey:press(source)
    self.lastTouchedBy = source

    -- If the key is not already initially pressed
    if self.state == 0 then
        self.state = 1

        -- Signal that the key has been initially pressed
        return true
    else
        self.state = 2
        return false
    end
end

function HoldableKey:release(source)
    if self.lastTouchedBy and self.lastTouchedBy ~= source then
        return false
    end

    self.lastTouchedBy = source

    -- If the key is not already released
    if self.state ~= 0 then
        self.state = 0

        -- Signal that they key has been released
        return true
    else
        return false
    end
end
