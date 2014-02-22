require('util.graphics')

PauseMenu = class('PauseMenu')

function PauseMenu:init()
end

function PauseMenu:draw()
    local items = {'RESUME',
                   'OPTIONS',
                   'NEW GAME',
                   'QUIT'}

    for _, item in pairs(items) do
    end

    cga_print('PAUSED', 1, 1)
end

function PauseMenu:key_pressed(key)
end

function PauseMenu:key_released(key)
end
