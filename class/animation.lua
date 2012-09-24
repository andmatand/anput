Animation = class('Animation')

function Animation:init(frames)
    self.frames = frames

    self:advance_to_frame(1)
    self.loop = true
    self.isStopped = false
end

function Animation:advance_to_frame(num)
    self.currentFrame = {index = num,
                         image = self.frames[num].image,
                         delay = self.frames[num].delay,
                         timer = 0}

    self.isStopped = false
end

function Animation:get_drawable()
    return self.currentFrame.image
end

function Animation:is_stopped()
    return self.isStopped
end

function Animation:update()
    -- If there's nothing to animate
    if not self.frames or #self.frames < 2 then
        return
    end

    if self.currentFrame.timer < self.currentFrame.delay then
        self.currentFrame.timer = self.currentFrame.timer + 1
    end

    if self.currentFrame.timer == self.currentFrame.delay then
        if self.currentFrame.index + 1 <= #self.frames then
            self:advance_to_frame(self.currentFrame.index + 1)
        else
            if self.loop then
                -- Wrap around to the first frame
                self:advance_to_frame(1)
            else
                self.isStopped = true
            end
        end
    end
end
