require('class.message')

-- A mouth enables something to "speak" (instantiate messages which appear
-- onscreen)
Mouth = class('Mouth')

function Mouth:init(args)
    self.sprite = args.sprite
    self.room = args.room

    self.isSpeaking = false
end

function Mouth:set_speech(text)
    -- Make a copy of the given text
    self.speech = '' .. text
end

function Mouth:should_speak()
    local position

    if self.isSpeaking then
        return false
    end

    -- If we are attached to a sprite
    if self.sprite then
        -- Set our position and room to those of the sprite
        position = self.sprite:get_position()
        self.room = self.sprite.room
    end

    -- If we have a position and room
    if position and self.room then
        -- If the player just moved, or the room has not been drawn
        if self.room.game.player.moved or not self.room.drawn then
            -- If the player is standing right next to us
            if tiles_touching(position, self.room.game.player.position) then
                return true
            end
        end
    end

    return false
end

function Mouth:shut()
    -- If we have a room
    if self.room then
        -- Find the message we were saying
        for i, m in pairs(self.room.messages) do
            if m.mouth == self then
                -- Remove the message from the queue
                table.remove(self.room.messages, i)

                self.isSpeaking = false
                break
            end
        end
    end
end

function Mouth:speak(cancelLastSpeech)
    if self.isSpeaking then
        if cancelLastSpeech then
            self:shut()
        else
            return
        end
    end

    -- If we are attached to a sprite
    if self.sprite then
        -- Set our room to that of the sprite
        self.room = self.sprite.room
    end

    self.isSpeaking = true

    -- If we have a room
    if self.room then
        -- Create a new message object
        msg = Message({room = self.room, avatar = self.sprite, mouth = self,
                       text = self.speech})

        -- Add the message to our room
        self.room:add_message(msg)
    end
end
