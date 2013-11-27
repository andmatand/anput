MessageQueue = class('MessageQueue')

function MessageQueue:init()
    self.messages = {}
    self.newMessageTimer = {value = 0, delay = 2}
end

function MessageQueue:add(message)
    table.insert(self.messages, message)
end

function MessageQueue:draw()
    -- If there is a message on the queue
    if self.messages[1] then
        -- Draw the message
        self.messages[1]:draw()
    end
end

function MessageQueue:is_empty()
    if self.messages[1] then
        return false
    else
        return true
    end
end

function MessageQueue:update()
    -- If there is no message on the front of the queue
    if not self.messages[1] then
        return
    end

    if self.newMessageTimer.value > 0 then
        self.newMessageTimer.value = self.newMessageTimer.value - 1
    else
        self.messages[1]:update()
    end

    local removeMessage = false

    -- If the message is finished displaying
    if self.messages[1].finished then
        -- Remove it from the queue
        removeMessage = true

    -- If the message's mouth is no longer in the room
    elseif self.messages[1].mouth and self.messages[1].mouth.sprite and
           self.messages[1].mouth.sprite.room ~= self then
        -- Move the message to the new room
        self.messages[1].mouth.sprite.room:add_message(self.messages[1])
        removeMessage = true
    end

    if removeMessage then
        local oldMessage = self.messages[1]

        -- Remove the first message from the queue
        table.remove(self.messages, 1)

        local newMessage = self.messages[1]

        -- If there is another message on the queue
        if newMessage then
            -- If the new message has a different speaker
            if newMessage.avatar ~= oldMessage.avatar or
               newMessage.mouth ~= oldMessage.mouth then
               -- Start a timer so that the next message does not display
               -- in the very next frame
               self.newMessageTimer.value = self.newMessageTimer.delay
            else
                -- Start the next message now
                newMessage:update()
            end
        end
    end
end
