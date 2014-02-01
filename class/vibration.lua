Vibration = class('Vibration')

function Vibration:init(joystick, left, right, duration)
    self.joystick = joystick
    self.timer = {delay = duration, value = 0}
    self.left = left
    self.right = right

    self.isVibrating = false
end

function Vibration:start()
    self.joystick:setVibration(self.left, self.right)
    self.isVibrating = true
end

function Vibration:stop()
    local left = nil
    local right = nil
    if self.left > 0 then
        left = 0
    end
    if self.right > 0 then
        right = 0
    end

    self.joystick:setVibration(left, right)
    self.isVibrating = false
end

function Vibration:update(dt)
    if self.isVibrating then
        if self.timer.value < self.timer.delay then
            self.timer.value = self.timer.value + dt
        end

        if self.timer.value >= self.timer.delay then
            self:stop()
        end
    end
end
