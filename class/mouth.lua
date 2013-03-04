require('class.message')
require('util.tables')

-- A mouth enables something to "speak" (instantiate messages which appear
-- onscreen)
Mouth = class('Mouth')

function Mouth:init(args)
    self.sprite = args.sprite
    self.room = args.room

    self.isSpeaking = false
    self.speakToNeighbor = true
end

function Mouth:get_speech()
    if not self.lines then
        return nil
    end

    -- Advance to the next line of dialogue
    self.lineIndex = self.lineIndex + 1
    if self.lineIndex > #self.lines then
        self.lineIndex = 1
    end

    return self.lines[self.lineIndex]
end

-- lines: can be a string or a table
function Mouth:set_speech(speech)
    if type(speech) == 'string' then
        -- If the speech is the same as our curent line
        if self.lines and speech == self.lines[1] then
            return
        end

        self.lines = {speech}
    elseif type(speech) == 'table' then
        -- If the speech is the same as our curent table of lines
        if self.lines and tables_have_equal_values(speech, self.lines) then
            return
        end

        self.lines = speech
    else
        self.lines = nil
    end

    self.lineIndex = 0
end

function Mouth:should_speak()
    local position

    if self.isSpeaking or not self.lines then
        return false
    end

    -- If we are attached to a sprite
    if self.sprite then
        -- Set our position and room to those of the sprite
        position = self.sprite:get_position()
        self.room = self.sprite.room
    end

    -- If we have a position and room and we speak to the player when he is
    -- touching us
    if position and self.room and self.speakToNeighbor then
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

function Mouth:speak(interruptLastLine)
    if self.isSpeaking then
        if interruptLastLine then
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
                       text = self:get_speech()})

        -- Add the message to our room
        self.room:add_message(msg)
    end
end
