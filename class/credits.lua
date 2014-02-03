require('class.timer')
require('util.graphics')

Credits = class('Credits')

function Credits:init()
    self.timer = Timer(FPS_LIMIT * 6)
    self.isPaused = false

    self.index = 0
    self.credits = {
        {'WITH', 'SCARAB BEETLE'},
        {'WITH', 'BIRD'},
        {'WITH', 'CAT'},
        {'WITH', 'COBRA'},
        {'WITH', 'MUMMY'},
        {'WITH', 'ARCHER'},
        {'WITH', 'GHOST'},
        {'STARRING', 'MAGICIAN'},
        {'STARRING', 'KHNUM'},
        {'STARRING', 'KHNUM\nAND THE CLAY GOLEMS'},
        {'STARRING', 'SET'},
        {'AND INTRODUCING', 'CAMEL'},

        {'CREATED BY', 'ANDREW ANDERSON'},
        {'SHINY THING ANIMATION', 'AUBRIANNE ANDERSON'},
        {'SPECIAL THANKS', 'LÖVE\nLOVE2D.ORG'},
        {'SPECIAL THANKS', 'EVERYONE WHO PLAYTESTED'},
        {'SPECIAL THANKS', 'EGYPT'},
        {'WINNER', 'YOU'}
    }
end

function Credits:play()
    self.isPaused = false
end

function Credits:pause()
    self.isPaused = true
end

function Credits:update()
    if self.isPaused then return end

    if self.timer:update() then
        self.timer:reset()

        if self.index < #self.credits then
            self:advance()
        end
    end
end

function Credits:advance()
    if self.index < #self.credits then
        self.index = self.index + 1
    end
end

function Credits:draw()
    cga_print(GAME_TITLE, GRID_W / 2, 2, {center = true})

    if self.index >= 1 and self.index <= #self.credits then
        local title, name = unpack(self.credits[self.index])

        cga_print(title, GRID_W / 2, 6, {color = MAGENTA, center = true})
        cga_print(name, GRID_W / 2, 7, {center = true})
    end
end
