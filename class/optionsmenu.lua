require('class.menu')
require('class.audiomenu')
require('class.videomenu')

OptionsMenu = class('OptionsMenu', Menu) 

function OptionsMenu:init(manager)
    self.manager = manager

    local items = {'AUDIO',
                   'VIDEO'}

    OptionsMenu.super.init(self, 'OPTIONS', items)
    self.y = self.y - 1
end

function OptionsMenu:execute_item(index)
    if index == 1 then -- AUDIO
        self.manager:push(AudioMenu())
    elseif index == 2 then -- VIDEO
        self.manager:push(VideoMenu())
    end
end
