-- A piece of Toast appears and then leaves off the bottom of the screen
-- according to a timer
Toast = class('Toast')

function Toast:init()
    -- Begin offscreen
    self.position = {y = upscale_y(ROOM_H)}
    self.offset = {y = upscale_y(1)}
    self.visible = false

    self.hideTimer = {delay = FPS, value = 0}
    self.frozen = false
end

function Toast:freeze()
    self.frozen = true
end

function Toast:get_y()
    return self.position.y + self.offset.y
end

function Toast:is_visible()
    if self.offset.y >= upscale_y(1) then
        return false
    else
        return true
    end
end

function Toast:show()
    self.visible = true
    self.offset.y = 0
    self.velocity = 1
    self.hideTimer.value = self.hideTimer.delay
end

function Toast:unfreeze()
    self.frozen = false
end

function Toast:update()
    -- If the scale changed
    if self.scale ~= SCALE_X then
        self.scale = SCALE_X
        self.position.y = upscale_y(ROOM_H)
    end

    if self.frozen then
        return
    end

    if not self.visible then
        -- Reset y offset in case the scale changed
        self.offset.y = upscale_y(1)
    end

    -- If the hide-timer is not already set, and We haven't started moving
    -- offscreen
    if self.hideTimer.value == 0 and self.offset.y == 0 then
        -- Set the delay timer before we hide
        self.hideTimer.value = self.hideTimer.delay

    -- If the hide-timer is still running
    elseif self.hideTimer.value > 0 then
        -- Decrement the hide-timer
        self.hideTimer.value = self.hideTimer.value - 1
    end

    -- If the hide-timer's delay period is over
    if self.hideTimer.value == 0 then
        -- If we are not already all the way hidden
        if self.offset.y < upscale_y(1) then
            -- Move down a little
            self.velocity = self.velocity * 1.5
            self.offset.y = self.offset.y + self.velocity
        else
            self.visible = false
        end
    end
end
