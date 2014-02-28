require('class.menu')

VideoMenu = class('VideoMenu', Menu)

function VideoMenu:init()
    --local names = {'FULLSCREEN',
    --               'GRAPHICS SCALE'}

    local names = {'', ''}

    local options = {}
    --options[1] = {'ON', 'OFF'}
    options[1] = {'WINDOW', 'FULLSCREEN'}
    options[2] = {'1X SCALE', '2X SCALE', '3X SCALE', '4X SCALE', '5X SCALE'}

    VideoMenu.super.init(self, 'VIDEO OPTIONS', names, options)
    self.y = self.y - 1

    self:ensure_setting_accuracy()
end

function VideoMenu:apply_option(index)
    if index == 1 then -- RESUME
        set_fullscreen((self.items[1].optionIndex == 2))
    elseif index == 2 then
        set_scale(self.items[2].optionIndex)
    end
end

function VideoMenu:update()
    VideoMenu.super.update(self)

    self:ensure_setting_accuracy()
end

-- Update settings that could have changed via other keyboard shortcuts
function VideoMenu:ensure_setting_accuracy()
    local _, _, flags = love.window.getMode()
    if flags.fullscreen then
        self.items[1]:select_option(2)
        self.items[2]:hide()
    else
        self.items[1]:select_option(1)
        self.items[2]:show()
    end

    self.items[2].optionIndex = SCALE_X
end
