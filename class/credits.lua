require('class.timer')
require('util.graphics')

Credits = class('Credits')

function Credits:init()
    self.timer = Timer(FPS_LIMIT * 6)

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
        {'STARRING', 'SET'},
        {'INTRODUCING', 'CAMEL'},
    }
    --self.credits = {
    --    {'ORIGINAL INSPIRATION', 'WWW.HOMESTARRUNNER.COM/SBEMAIL4.HTML'},
    --    {'INSPIRATION', 'ADVENTURE\nFOR ATARI 2600'},
    --    {'INSPIRATION', 'FEZ'},
    --    {'INSPIRATION', 'THE LEGEND OF ZELDA'},
    --    {'INSPIRATION', 'NETHACK'},
    --    {'INSPIRATION', 'EGYPT'},
    --    {'SHINY THING ANIMATION', 'AUBRIANNE ANDERSON'},
    --    {'MORAL SUPPORT', 'AUBRIANNE ANDERSON'},
    --    {'EVERYTHING ELSE', 'ANDREW ANDERSON'},
    --    {'SPECIAL THANKS', 'LOVE\nLOVE2D.ORG'},
    --    {'SPECIAL THANKS', 'LUA\nLUA.ORG'},
    --    {'SPECIAL THANKS', 'EVERYONE WHO PLAYTESTED THE GAME'},
    --    {'WINNER', 'YOU'},
    --}
end

--function Credits:update()
--    if self.timer:update() then
--        self.timer:reset()
--
--        if self.index < #self.credits then
--            self.index = self.index + 1
--        end
--    end
--end

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
