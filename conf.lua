function love.conf(t)
    t.modules.joystick = false
    t.modules.physics = false
    t.version = '0.8.0'

    SCALE_X = 2
    SCALE_Y = 2
    --SCALE_Y = SCALE_Y * 1.2 -- Keep authentic 4:3 pixel aspect ratio

    t.screen.width = 320 * SCALE_X
    t.screen.height = 200 * SCALE_Y
end
