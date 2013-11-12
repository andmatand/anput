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

    -- Joystick/Gamepad Bindings
    -- (These are for an Xbox 360 controller; change them as needed for
    --  other joysticks/gamepads)
    JOYSTICK = {}
    JOYSTICK_NUM = 1 -- Use the first joystick/gamepad
    JOYSTICK.CONTEXT = 1 -- A
    JOYSTICK.DROP = 3 -- X
    JOYSTICK.ELIXIR = 3 -- X
    JOYSTICK.EXIT = 2 -- B
    JOYSTICK.PAUSE = 8 -- Start
    JOYSTICK.POTION = 2 -- B
    JOYSTICK.SKIP_CUTSCENE = 8 -- Start
    JOYSTICK.SKIP_DIALOG = 2 -- B
    JOYSTICK.SWITCH_WEAPON = 4 -- Y
    JOYSTICK.SHOOT_AXIS_X = 4 -- Right stick
    JOYSTICK.SHOOT_AXIS_Y = 5
    JOYSTICK.SHOOT_HAT = nil -- Disabled
    JOYSTICK.WALK_AXIS_X = 1 -- Left stick
    JOYSTICK.WALK_AXIS_Y = 2
    JOYSTICK.WALK_HAT = 1 -- D-Pad
end
