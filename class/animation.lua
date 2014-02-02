require('class.timer')

Animation = class('Animation')

function Animation:init(frames)
    self.frames = frames

    self:advance_to_frame(1)
    self.loop = true
    self.isStopped = false
end

function Animation:advance_to_frame(num)
    if self.frameCallbacks then
        -- If there is a callback function for this frame number
        if self.frameCallbacks[num] then
            -- Call this frame's callback function
            self.frameCallbacks[num]()
        end
    end

    self.currentFrame = {index = num,
                         image = self.frames[num].image,
                         timer = Timer(self.frames[num].delay)}

    self.isStopped = false
end

function Animation:get_drawable()
    return self.currentFrame.image
end

function Animation:is_at_beginning()
    if self.currentFrame.index == 1 and
       self.currentFrame.timer:is_at_beginning() then
        return true
    else
        return false
    end
end

function Animation:is_stopped()
    return self.isStopped
end

function Animation:update()
    -- If there's nothing to animate
    if not self.frames or #self.frames < 2 or self.isStopped then
        return
    end

    if self.currentFrame.timer:update() then
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
