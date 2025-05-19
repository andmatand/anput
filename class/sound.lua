Sound = class('Sound')

function Sound:init(file)
    self.source = love.audio.newSource(file, 'static')
end

function Sound:play()
    if self.varyPitch then
        self.source:setPitch(1 + love.math.random(-8, 8) / 100)
    end

    if not self.source:isPlaying() then
        self.source:play()
    else
        self.source:seek(0)
    end
end
