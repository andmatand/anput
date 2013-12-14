require('util.oo')
require('class.golem')
require('class.sound')
require('class.wrapper')
require('util.graphics')

function love.load()
    love.window.setTitle('TEMPLE OF ANPUT')
    if love.graphics.isCreated() == false then
        print('failed to create a window')
    end
    love.mouse.setVisible(false)

    KEYS = {CONTEXT = 1,
            ELIXIR = 2,
            EXIT = 3,
            PAUSE = 6,
            POTION = 7,
            SKIP_CUTSCENE = 8,
            SKIP_DIALOG = 9,
            SWITCH_WEAPON = 11,
            SHOOT = {NORTH = 12,
                     EAST = 13,
                     SOUTH = 14,
                     WEST = 15},
            WALK = {NORTH = 16,
                    EAST = 17,
                    SOUTH = 18,
                    WEST = 19},
            WEAPON_SLOT_1 = 20,
            WEAPON_SLOT_2 = 21,
            WEAPON_SLOT_3 = 22,
            WEAPON_SLOT_4 = 23,
            WEAPON_SLOT_5 = 24}

    -- Set the width and height of the tile grid (in # of tiles)
    GRID_W = BASE_SCREEN_W / TILE_W
    GRID_H = BASE_SCREEN_H / TILE_H

    -- These dimensions are in number of tiles (not pixels)
    ROOM_W = GRID_W
    ROOM_H = GRID_H - 1

    -- Set default image filter to show ALL the pixels
    love.graphics.setDefaultFilter('nearest', 'nearest')

    set_scale(SCALE_X, nil, false)

    -- Colors
    BLACK = {0, 0, 0}
    WHITE = {255, 255, 255}
    CYAN = {85, 255, 255}
    MAGENTA = {255, 85, 255}

    -- Alpha values
    LIGHT = 255
    DARK = 15

    local function new_image(filename)
        local img = love.graphics.newImage('res/img/' .. filename)
        --img:setFilter('nearest', 'nearest')
        return img
    end

    local function load_images(directory, names)
        local images = {}
        for _, n in pairs(names) do
            images[n] = new_image(directory .. n .. '.png')
        end

        return images
    end

    images = {}
    playerImg = {default = new_image('player.png'),
                 sword = new_image('player-sword.png'),
                 bow = new_image('player-bow.png'),
                 horn = new_image('player-horn.png'),
                 firestaff = new_image('player-firestaff.png'),
                 thunderstaff = new_image('player-thunderstaff.png')}

    -- Monsters
    images.monsters = {}
    images.monsters.scarab = {default = new_image('scarab.png'),
                              step = new_image('scarab-step.png')}
    images.monsters.bird = {default = new_image('bird.png'),
                            dodge = new_image('bird-dodge.png'),
                            step = new_image('bird-step.png')}
    images.monsters.cat = {default = new_image('cat.png'),
                           walk = new_image('cat-walk.png'),
                           attack = new_image('cat-attack.png')}
    images.monsters.cobra = {default = new_image('cobra.png'),
                             walk = {{image = new_image('cobra-walk1.png'),
                                      delay = 2},
                                     {image = new_image('cobra-walk2.png'),
                                      delay = 2}},
                             attack = new_image('cobra-attack.png')}
    images.monsters.golem = {default = new_image('golem.png'),
                             step = new_image('golem-step.png'),
                             attack = new_image('golem-attack.png'),
                             spawn = {{image = new_image('golem-spawn1.png'),
                                      delay = 4},
                                     {image = new_image('golem-spawn2.png'),
                                      delay = 4},
                                     {image = new_image('golem-spawn3.png'),
                                      delay = 4},
                                     {image = new_image('golem-spawn4.png'),
                                      delay = 4},
                                     {image = new_image('golem-spawn5.png'),
                                      delay = 4}}}
    images.monsters.mummy = {default = new_image('mummy.png'),
                             walk = new_image('mummy-walk.png'),
                             firestaff = new_image('mummy-firestaff.png')}
    images.monsters.archer = {bow = new_image('archer-bow.png'),
                              sword = new_image('archer-sword.png')}
    images.monsters.ghost = {default = new_image('ghost.png')}

    -- NPCs
    images.npc = {}
    images.npc.camel = {default = new_image('camel.png'),
                        step = new_image('camel-step.png')}
    images.npc.khnum = {default = new_image('khnum.png')}
    images.npc.set = {default = new_image('set.png')}
    images.npc.wizard = {default = new_image('wizard.png'),
                         firestaff = new_image('wizard-firestaff.png')}

    -- Projectiles
    projectileImg = {}
    projectileImg.arrow = {new_image('item/arrow.png')}
    projectileImg.fireball = {new_image('fireball1.png'),
                              new_image('fireball2.png')}

    -- Items
    images.items = load_images('item/',
                               {'ankh', 'arrow', 'bow', 'firestaff', 'flask',
                                'horn', 'sword', 'thunderstaff'})
    images.items.shinything = {new_image('item/shiny-1.png'),
                               new_image('item/shiny-2.png'),
                               new_image('item/shiny-3.png')}

    -- Furniture
    images.door = new_image('door.png')
    images.spike = new_image('spike.png')
    images.switch = {{image = new_image('switch1.png'), delay = 2},
                     {image = new_image('switch2.png'), delay = 2},
                     {image = new_image('switch3.png'), delay = 2}}

    -- Buttons
    images.buttons = load_images('button/',
                                 {'w', 'a', 's', 'd', 'enter', 'up', 'right',
                                 'left', 'down'})

    -- Hieroglyphs
    images.hieroglyphs = load_images('hieroglyph/',
                                     {'h', 'hnm', 'i', 'ka', 'n_p', 's', 'sw',
                                      't', 't_sh', 't_y', 'w', 'y',
                                      'book', 'god', 'goddess', 'khnum',
                                      'lake', 'set', 'water'})

    -- Outside
    outsideImg = {}
    outsideImg.museum = {image = new_image('museum.png'),
                         avatar = new_image('museum-avatar.png')}
    outsideImg.temple = {image = new_image('temple.png')}


    -- Water
    images.water = {new_image('water1.png'),
                    new_image('water2.png'),
                    new_image('water3.png')}
    table.insert(images.water, images.water[2])

    -- Create image data for a brick (a magenta rectangle)
    local brickImgData = love.image.newImageData(TILE_W, TILE_H)
    for y = 0, brickImgData:getHeight() - 1 do
        for x = 0, brickImgData:getWidth() - 1 do
            brickImgData:setPixel(x, y,
                                  MAGENTA[1], MAGENTA[2], MAGENTA[3], 255)
        end
    end
    -- Store the brick image
    brickImg = love.graphics.newImage(brickImgData)


    -- Sounds
    sounds = {}
    sounds.door = {open1 = Sound('res/sfx/door-open1.wav'),
                   open2 = Sound('res/sfx/door-open2.wav'),
                   open3 = Sound('res/sfx/door-open3.wav'),
                   open4 = Sound('res/sfx/door-open4.wav'),
                   open5 = Sound('res/sfx/door-open5.wav')}
    sounds.theme = Sound('res/sfx/theme.wav')
    sounds.player = {cry = Sound('res/sfx/player-cry.wav'),
                     die = Sound('res/sfx/player-die.wav'),
                     getItem = Sound('res/sfx/player-get-item.wav'),
                     dropItem = Sound('res/sfx/player-drop-item.wav'),
                     getHP = Sound('res/sfx/player-get-hp.wav'),
                     getMagic = Sound('res/sfx/player-get-magic.wav')}
    sounds.monster = {cry = Sound('res/sfx/monster-cry.wav'),
                      die = Sound('res/sfx/monster-die.wav'),
                      getItem = Sound('res/sfx/monster-get-item.wav'),
                      dropItem = Sound('res/sfx/monster-drop-item.wav'),
                      getHP = Sound('res/sfx/monster-get-hp.wav'),
                      getMagic = Sound('res/sfx/monster-get-magic.wav')}
    sounds.camel = {run = Sound('res/sfx/camel-run.wav'),
                    caught = Sound('res/sfx/camel-caught.wav'),
                    gulp = Sound('res/sfx/camel-gulp.wav')}
    sounds.golem = {spawn = Sound('res/sfx/golem-spawn.wav')}
    sounds.khnum = {encounter = Sound('res/sfx/khnum-encounter.wav')}
    sounds.shootArrow = Sound('res/sfx/shoot-arrow.wav')
    sounds.unable = Sound('res/sfx/unable.wav')
    sounds.thud = Sound('res/sfx/thud.wav')
    sounds.thud.varyPitch = true
    sounds.pause = Sound('res/sfx/pause.wav')
    sounds.menuSelect = Sound('res/sfx/menu-select.wav')
    sounds.secret = Sound('res/sfx/secret.wav')
    sounds.set = {encounter = Sound('res/sfx/set-encounter.wav'),
                  teleport = Sound('res/sfx/set-teleport.wav')}
    sounds.spikes = Sound('res/sfx/spikes-trigger.wav')
    sounds.trap = Sound('res/sfx/trap.wav')

    --mute = true
    FPS_LIMIT = 15

    -- Create a new wrapper object
    wrapper = Wrapper()
end

function love.update(dt)
    wrapper:update(dt)
end

function jump_to_room(index)
    if index >= 1 and index <= #wrapper.game.rooms then
        local newRoom = wrapper.game.rooms[index]
        wrapper.game:switch_to_room(newRoom)
        wrapper.game.player:move_to_room(newRoom)
        wrapper.game.player:set_position(newRoom.midPoint)
    end
end

function translate_direction(direction)
    if type(direction) == 'string' then
        if direction == 'up' then
            return 1
        elseif direction == 'right' then
            return 2
        elseif direction == 'down' then
            return 3
        elseif direction == 'left' then
            return 4
        end
    end
end

function jump_to_room_in_direction(direction)
    local currentNode

    -- Find the current room's map node
    for _, n in pairs(wrapper.game.map.nodes) do
        if n.room == wrapper.game.currentRoom then
            currentNode = n
            break
        end
    end

    -- Find the target position
    local dir = translate_direction(direction)
    local targetPos = add_direction(currentNode, dir)

    -- Find the node that overlaps with the target position
    for _, n in pairs(wrapper.game.map.nodes) do
        if tiles_overlap(n, targetPos) then
            jump_to_room(n.room.index)
            return
        end
    end
end

function love.joystickadded(joystick)
    print('joystickadded')
    wrapper:joystick_added(joystick)
end

function love.gamepadpressed(joystick, button)
    wrapper:gamepad_pressed(joystick, button)
    --gamepadButton = button
end

function love.gamepadreleased(joystick, button)
    wrapper:gamepad_released(joystick, button)
end

function love.joystickremoved(joystick)
    wrapper:joystick_removed(joystick)
end

function love.keypressed(key, unicode)
    local ctrl, shift
    if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
        ctrl = true
    end
    if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
        shift = true
    end

    if ctrl and key == 'n' then
        wrapper:restart()
    elseif key == 'f11' or
           ((love.keyboard.isDown('ralt') or love.keyboard.isDown('lalt'))
            and key == 'return') then
        toggle_fullscreen()
    elseif ctrl and key == 'q' then
        love.event.quit()
    elseif ctrl and (key == '=' or key == '+') then
        set_scale(SCALE_X + 1)
    elseif ctrl and key == '-' then
        set_scale(SCALE_X - 1)

    -- DEBUG commands
    elseif ctrl and shift then
        if key == 'f1' then
            DEBUG = not DEBUG
            wrapper.game.currentRoom.bricksDirty = true
        elseif key == 'i' then
            wrapper.game.player.isInvincible =
                not wrapper.game.player.isInvincible
        elseif key == 'j' then
            jump_to_room(wrapper.game.currentRoom.index + 1)
        elseif key == 'k' then
            jump_to_room(wrapper.game.currentRoom.index - 1)
        elseif key == 'up' or key == 'right' or key == 'down' or
               key == 'left' then
            jump_to_room_in_direction(key)
        elseif key == 'a' then
            local artifact = Item('ankh')
            wrapper.game.player:pick_up(artifact)
        elseif key == 'b' then
            if not wrapper.game.player.armory.weapons.bow then
                local bow = Weapon('bow')
                wrapper.game.player:pick_up(bow)
            end
            wrapper.game.player.armory.weapons.bow:add_ammo(20)
        elseif key == 'c' then
            --for _, c in pairs(wrapper.game.currentRoom:get_characters()) do
            --    if c.name then
            --        c.ai:chase(wrapper.game.player)
            --    end
            --end

            local camel = Camel()
            camel.state = 'caught'
            camel.ai.level.globetrot.prob = nil
            camel.isCaught = true
            camel.ai.level.follow.prob = 10
            camel.ai.level.follow.target = wrapper.game.player
            camel:set_position(wrapper.game.currentRoom:get_free_tile())
            wrapper.game.currentRoom:add_object(camel)
        elseif key == 'd' then
            wrapper.game:set_demo_mode(not wrapper.game.demoMode)
            print('demo mode: ', wrapper.game.demoMode)
        elseif key == 'e' then
            local elixir = Item('elixir')
            wrapper.game.player:pick_up(elixir)
        elseif key == 'f' then
            local firestaff = Weapon('firestaff')
            wrapper.game.player:pick_up(firestaff)
        elseif key == 'g' then
            -- Give the player some goodies!
            for i = 1, 7 do
                local item = Item('shinything')
                wrapper.game.player:pick_up(item)
            end
        elseif key == 'h' then
            wrapper.game.player:add_health(100)
        elseif key == 'o' then
            local horn = Horn()
            wrapper.game.player:pick_up(horn)
        elseif key == 'p' then
            local potion = Item('potion')
            wrapper.game.player:pick_up(potion)
        elseif key == 's' then
            if wrapper.game.currentRoom then
                for _, spike in pairs(wrapper.game.currentRoom.spikes) do
                    spike:trigger()
                end
            end
        elseif key == 't' then
            local thunderstaff = ThunderStaff()
            wrapper.game.player:pick_up(thunderstaff)
        elseif key == 'z' then
            wrapper.game.player:receive_damage(100, wrapper.game.player)
        end
    else
        wrapper:key_pressed(key)
    end
end

function love.keyreleased(key, unicode)
    wrapper:key_released(key)
end

function love.draw()
    --if wrapper.game.player then
    --    sx = ((ROOM_W / 2) - wrapper.game.player.position.x) * .002
    --    sy = ((ROOM_H / 2) - wrapper.game.player.position.y) * .002
    --    love.graphics.shear(sx, sy)
    --end

    love.graphics.setScissor(SCREEN_X, SCREEN_Y,
                             BASE_SCREEN_W * SCALE_X, BASE_SCREEN_H * SCALE_Y)
    love.graphics.translate(SCREEN_X, SCREEN_Y)

    if DEBUG and wrapper.game.player then
        local pos = wrapper.game.player:get_position()
        cga_print(pos.x .. ' ' .. pos.y, 1, 1)
    end

    wrapper:draw()

    love.graphics.setScissor()

    --if gamepadButton then
    --    cga_print(gamepadButton:upper(), 1, 1)
    --end
    --if wrapper.game.player then
    --    local txt = wrapper.game.player.position.x .. ' ' ..
    --                wrapper.game.player.position.y
    --    cga_print(txt, 1, 1)
    --end
end

-- Returns distance between two tiles
function distance(a, b)
    return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
end
