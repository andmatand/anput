Timer = class('Timer')

function Timer:init(delay)
    self.delay = delay

    self:reset()
end

function Timer:reset()
    self.value = self.delay
end

function Timer:update()
    if self.value > 0 then
        self.value = self.value - 1
        return false
    else
        return true
    end
end
