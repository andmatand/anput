Sound = class('Sound')

function Sound:init(file)
	self.file = file
	self.sources = {}

	-- Add one source to begin with
	self:add_source()
end

function Sound:add_source()
	table.insert(self.sources, love.audio.newSource(self.file, 'static'))
end

function Sound:play()
	for _, s in pairs(self.sources) do
		if s:isStopped() then
			s:play()
		else
			s:rewind()
		end
	end
	return

	--self:add_source()
	--love.audio.play(self.sources[#self.sources])
end
