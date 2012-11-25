function love.conf(t)
    t.modules.joystick = false
    t.modules.physics = false
    t.version = '0.8.0'

    BASE_SCREEN_W = 320
    BASE_SCREEN_H = 200
    SCALE_X = 3
    SCALE_Y = 3

    -- Keep authentic 4:3 pixel aspect ratio
    --SCALE_Y = SCALE_Y * 1.2

    t.screen.width = BASE_SCREEN_W * SCALE_X
    t.screen.height = BASE_SCREEN_H * SCALE_Y
end
