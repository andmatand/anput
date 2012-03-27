-- A mouth enables something to "speak" (instantiate messages which appear
-- onscreen).
Mouth = class('Mouth')

function Mouth:init(args)
	self.character = args.character
end

function Mouth:should_speak()
	-- If we are attached to a character
	if self.character and self.speech then
		-- If the player is standing right next to us
		if tiles_touching(self.character.position,
		                  self.character.room.game.player.position) then
			return true
		end
	end

	return false
end

function Mouth:speak()
end
