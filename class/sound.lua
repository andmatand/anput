Sound = class('Sound')

function Sound:init(file)
    self.source = love.audio.newSource(file, 'static')
end

function Sound:play()
    if self.varyPitch then
        self.source:setPitch(1 + love.math.random(-8, 8) / 100)
    end

    if self.source:isStopped() then
        self.source:play()
    else
        self.source:rewind()
    end
end
