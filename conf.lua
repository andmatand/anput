function love.conf(t)
    t.modules.physics = false
    t.version = '0.9.0'

    BASE_SCREEN_W = 320
    BASE_SCREEN_H = 200
    TILE_W = 8
    TILE_H = 8
    SCALE_X = 3
    SCALE_Y = 3

    -- Keep authentic 4:3 pixel aspect ratio
    --SCALE_Y = SCALE_Y * 1.2

    t.window.title = 'TEMPLE OF ANPUT'
    t.window.width = BASE_SCREEN_W * SCALE_X
    t.window.height = BASE_SCREEN_H * SCALE_Y

    -- Keyboard Bindings
    KEYBOARD = {}
    KEYBOARD.CONTEXT = 'return'
    KEYBOARD.DROP = 'delete'
    KEYBOARD.ELIXIR = 'e'
    KEYBOARD.EXIT = 'escape'
    KEYBOARD.PAUSE = ' '
    KEYBOARD.POTION = 'p'
    KEYBOARD.SKIP_CUTSCENE = 'escape'
    KEYBOARD.SKIP_DIALOG = '.'
    KEYBOARD.SWITCH_WEAPON = 'shift'
    KEYBOARD.SHOOT = {NORTH = 'up',
                      EAST  = 'right',
                      SOUTH = 'down',
                      WEST  = 'left'}
    KEYBOARD.WALK = {NORTH = 'w',
                     EAST  = 'd',
                     SOUTH = 's',
                     WEST  = 'a'}

    -- Gamepad Bindings (Works with XBox 360 and similar controllers)
    GAMEPAD = {}
    GAMEPAD.CONTEXT = 'a'
    GAMEPAD.DROP = 'x'
    GAMEPAD.ELIXIR = 'x'
    GAMEPAD.EXIT = 'b'
    GAMEPAD.PAUSE = 'start'
    GAMEPAD.POTION = 'b'
    GAMEPAD.SKIP_CUTSCENE = 'start'
    GAMEPAD.SKIP_DIALOG = 'b'
    GAMEPAD.SWITCH_WEAPON = 'y'
    GAMEPAD.SHOOT_AXIS_X = 'rightx'
    GAMEPAD.SHOOT_AXIS_Y = 'righty'
    GAMEPAD.SHOOT = nil -- Shooting with buttons is disabled by default
    GAMEPAD.WALK_AXIS_X = 'leftx'
    GAMEPAD.WALK_AXIS_Y = 'lefty'
    GAMEPAD.WALK = {NORTH = 'dpup',
                    EAST  = 'dpright',
                    SOUTH = 'dpdown',
                    WEST  = 'dpleft'}
end
