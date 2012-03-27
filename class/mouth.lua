require('class/message')

-- A mouth enables something to "speak" (instantiate messages which appear
-- onscreen)
Mouth = class('Mouth')

function Mouth:init(args)
	self.sprite = args.sprite
	self.room = args.room

	self.isSpeaking = false
end

function Mouth:should_speak()
	local position

	if self.isSpeaking then
		return false
	end

	-- If we are attached to a sprite
	if self.sprite then
		-- Set our position and room to those of the sprite
		position = self.sprite.position
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

function Mouth:speak()
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
