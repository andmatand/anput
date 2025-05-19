function love.conf(t)
    t.accelerometerjoystick = false
    t.identity = 'anput'
    t.modules.physics = false
    t.modules.system = false
    t.modules.touch = false
    t.version = '11.4'

    BASE_SCREEN_W = 320
    BASE_SCREEN_H = 200
    TILE_W = 8
    TILE_H = 8
    SCALE_X = 3
    SCALE_Y = 3

    -- Keep authentic 4:3 pixel aspect ratio
    --SCALE_Y = SCALE_Y * 1.2

    -- Defer window creation until love.window.setMode is called in main.lua
    t.window = nil

    -- Keyboard Bindings
    KEYBOARD = {}
    KEYBOARD.CONTEXT = 'return'
    KEYBOARD.DROP = 'delete'
    KEYBOARD.ELIXIR = 'e'
    KEYBOARD.EXIT = 'escape'
    KEYBOARD.INVENTORY = 'space'
    KEYBOARD.PAUSE = 'escape'
    KEYBOARD.POTION = 'p'
    KEYBOARD.SKIP_CUTSCENE = 'escape'
    KEYBOARD.SKIP_DIALOGUE = '.'
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
    GAMEPAD.INVENTORY = 'back'
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
    AXIS_THRESHOLD = .8 -- Sensitivity for analog sticks.  Range is from 0 - 1,
                        -- lower being more sensitive)
end
