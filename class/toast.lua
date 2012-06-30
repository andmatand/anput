-- A piece of Toast appears and then leaves off the bottom of the screen
-- according to a timer
Toast = class('Toast')

function Toast:init()
    self.position = {y = upscale_y(ROOM_H)}

    -- Begin offscreen
    self.offset = {y = upscale_y(1)}

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
    self.offset.y = 0
    self.velocity = 1
    self.hideTimer.value = self.hideTimer.delay
end

function Toast:unfreeze()
    self.frozen = false
end

function Toast:update()
    if self.frozen then
        return
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

    -- If the hide-timer's delay period is over, and we are not already
    -- hidden
    if self.hideTimer.value == 0 and self.offset.y < upscale_y(1) then
        -- Move down a little
        --self.offset.y = self.offset.y + SCALE_Y
        self.velocity = self.velocity * 1.5
        self.offset.y = self.offset.y + self.velocity
    end
end
