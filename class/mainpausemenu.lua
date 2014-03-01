require('class.confirmmenu')
require('class.menu')
require('class.optionsmenu')

MainPauseMenu = class('MainPauseMenu', Menu) 

function MainPauseMenu:init(manager)
    self.manager = manager

    local newGame = function()
    end

    local items = {'RESUME',
                   'OPTIONS',
                   'NEW GAME',
                   'QUIT'}

    MainPauseMenu.super.init(self, 'PAUSED', items)
end

function MainPauseMenu:execute_item(index)
    if index == 1 then -- RESUME
        self:exit()
    elseif index == 2 then -- OPTIONS
        self.manager:push(OptionsMenu(self.manager))
    elseif index == 3 then -- NEW GAME
        callback = function()
            wrapper:restart()
        end

        self.manager:push(ConfirmMenu('REALLY?',
                                      'NEW GAME', 'CANCEL',
                                      callback))
    elseif index == 4 then -- QUIT
        callback = function()
            save_settings()
            love.event.quit()
        end

        self.manager:push(ConfirmMenu('REALLY?',
                                      'QUIT', 'KEEP PLAYING',
                                      callback))
    end
end
