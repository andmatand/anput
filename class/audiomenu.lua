require('class.menu')
require('util.settings')

AudioMenu = class('AudioMenu', Menu)

function AudioMenu:init()
    local names = {''}

    local options = {}
    options[1] = {'SILENCE', 'SOUNDS'}

    AudioMenu.super.init(self, 'AUDIO OPTIONS', names, options)
    self.y = self.y - 1

    self:match_actual_settings()
end

function AudioMenu:apply_option(index)
    if index == 1 then -- RESUME
        settings.sound = (self.items[1].optionIndex == 2)
        apply_sound_setting(settings.sound)
    end
end

function AudioMenu:update()
    AudioMenu.super.update(self)

    self:match_actual_settings()
end

function AudioMenu:match_actual_settings()
    if settings.sound then
        self.items[1].optionIndex = 2
    else
        self.items[1].optionIndex = 1
    end
end
