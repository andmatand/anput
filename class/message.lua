Message = class('Message')

function Message:init(args)
	self.text = args.text
	self.room = args.room
	self.mouth = args.mouth
	self.avatar = args.avatar

	-- Default to 1 frame per character
	self.delay = args.delay or self.text:len()

	self.cursor = 0 -- Last character currently visible (when unfurling text)
	self.position = {x = 0, y = 0}
	self.verticalAlign = 'top'

	-- Set the wrapwidth
	local wrapWidth = ROOM_W
	if self.avatar then
		-- Make room for the avatar
		wrapWidth = wrapWidth - 2
	end

	-- Wrap the text (add linebreaks)
	self:wrap(wrapWidth)
end

-- Decide on a good position that does not overlap with the player
function Message:choose_position()
	-- If we don't have a room
	if not self.room then
		-- We have no way of knowing where the player is, so use the default
		-- position.
		return
	end

	-- If the player is too close to our y position
	if math.abs(self.room.game.player.position.y -
	    self.position.y) <= self.numLines + 1 then
		-- Move to the other side of the room
		if self.position.y == 0 then
			self.position.y = ROOM_H - 1
			self.verticalAlign = 'bottom'
		else
			self.position.y = 0
			self.verticalAlign = 'top'
		end
	end
end

function Message:draw()
	local xOffset, yOffset

	if self.verticalAlign == 'bottom' then
		yOffset = -(self.numLines - 1)
	else
		yOffset = 0
	end

	-- If we have an avatar to draw before the text
	if self.avatar then
		-- Draw the avatar
		self.avatar:draw({x = self.position.x, y = self.position.y + yOffset})

		-- Print a colon after the avatar
		love.graphics.setColor(WHITE)
		tile_print(':',
		           self.position.x + 1,
		           self.position.y + yOffset,
		           self.wrapWidth)

		xOffset = 2
	else
		xOffset = 0
	end

	love.graphics.setColor(WHITE)

	-- Print (the currently unfurled portion of) the text
	tile_print(self:get_text(),
	           self.position.x + xOffset,
	           self.position.y + yOffset)
end

function Message:get_height()
	return self.numLines * FONT_H
end

-- Returns the portion of the text that has currently been unfurled
function Message:get_text()
	return self.text:sub(1, self.cursor)
end

function Message:update()
	-- If we are still unfurling the text
	if self.cursor < self.text:len() then
		self.cursor = self.cursor + 2
	else
		self.delay = self.delay - 1

		if self.delay <= 0 then
			self.finished = true

			-- If we have an associated mouth
			if self.mouth then
				self.mouth.isSpeaking = false
			end

			return
		end
	end

	self:choose_position()
end

local function next_word(string, start)
	local startOfWord = string:find('%S', start)

	if startOfWord then
		local nextSpace = string:find('%s', startOfWord)
		
		local endOfWord
		if nextSpace then
			endOfWord = nextSpace - 1
		else
			endOfWord =  string:len()
		end

		return string:sub(startOfWord, endOfWord), endOfWord
	else
		return nil
	end
end

-- Adds linebreaks to the string in the correct places
--     width: maximum number of characters
function Message:wrap(width)
	self.numLines = 1

	local cur = 1
	local x = 1
	repeat
		local nextWord, endOfWord
		nextWord, endOfWord = next_word(self.text, cur)

		-- If the end of the current word would exceed the wrap width
		if x + nextWord:len() >= width then
			-- Insert a linebreak before the current word
			self.text = self.text:sub(1, cur - 1) .. '\n' ..
			            self.text:sub(cur + 1)

			-- Keep track of the number of lines in the message
			self.numLines = self.numLines + 1

			-- Return x to the beginning of the line
			x = 0
		else
			x = x + (endOfWord - cur) + 1
		end

		-- Advance the cursor to the next word
		cur = endOfWord + 1
	until cur >= self.text:len()
end
