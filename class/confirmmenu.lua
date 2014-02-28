require('class.menu')

ConfirmMenu = class('ConfirmMenu', Menu)

function ConfirmMenu:init(title, option1, option2, option1Callback)
    local items = {option1, option2}
    self.option1Callback = option1Callback

    ConfirmMenu.super.init(self, title, items)
end

function ConfirmMenu:execute_item(index)
    if index == 1 then
        self.option1Callback()
    elseif index == 2 then
        self:exit()
    end
end
