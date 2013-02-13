Sound = class('Sound')

function Sound:init(file)
    self.file = file

    self.source = love.audio.newSource(self.file, 'static')
end

function Sound:play()
    if self.varyPitch then
        self.source:setPitch(1 + math.random(-8, 8) / 100)
    end

    if self.source:isStopped() then
        self.source:play()
    else
        self.source:rewind()
    end
end
