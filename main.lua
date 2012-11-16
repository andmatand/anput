require('util.oo')
require('class.sound')
require('class.wrapper')
require('util.graphics')

function love.load()
    love.graphics.setCaption('TEMPLE OF ANPUT')
    if love.graphics.isCreated() == false then
        print('failed to create a window')
    end
    love.mouse.setVisible(false)

    -- These are the tile dimensions in (unscaled) pixels
    TILE_W = 8
    TILE_H = 8

    -- These dimensions are in number of tiles (not pixels)
    ROOM_W = 40
    ROOM_H = 24

    -- Set default image fileter to show ALL the pixels
    love.graphics.setDefaultImageFilter('nearest', 'nearest')

    set_scale(SCALE_X)

    -- Colors
    BLACK = {0, 0, 0}
    WHITE = {255, 255, 255}
    CYAN = {85, 255, 255}
    MAGENTA = {255, 0, 255}

    -- Alpha values
    LIGHT = 255
    DARK = 20

    -- These are the dimensions of one letter of the font before scaling
    FONT_W = 8
    FONT_H = 8

    local function new_image(filename)
        img = love.graphics.newImage('res/img/' .. filename)
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
    images.monsters.mummy = {default = new_image('mummy.png'),
                             walk = new_image('mummy-walk.png')}
    images.monsters.archer = {bow = new_image('archer-bow.png'),
                              sword = new_image('archer-sword.png')}
    images.monsters.ghost = {default = new_image('ghost.png')}

    -- NPCs
    camelImg = {default = new_image('camel.png'),
                step = new_image('camel-step.png')}

    -- Projectiles
    projectileImg = {}
    projectileImg.arrow = {new_image('item/arrow.png')}
    projectileImg.fireball = {new_image('fireball1.png'),
                              new_image('fireball2.png')}

    -- Items
    images.items = load_images('item/',
                               {'ankh', 'arrow', 'bow', 'firestaff', 'flask',
                                'sword', 'thunderstaff'})
    images.items.shinything = {new_image('item/shiny-1.png'),
                               new_image('item/shiny-2.png'),
                               new_image('item/shiny-3.png')}

    -- Verbs
    images.verbs = load_images('', {'drop', 'use'})

    -- Buttons
    buttonImg = {
        w = new_image('button/w.png'),
        a = new_image('button/a.png'),
        s = new_image('button/s.png'),
        d = new_image('button/d.png'),
        enter = new_image('button/enter.png')}

    -- Hieroglyphs
    images.hieroglyphs = load_images('hieroglyph/',
                                     {'h', 'i', 'ka', 'n_p', 's', 't', 't_sh',
                                      'w', 'y', 'book', 'god', 'goddess'})

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
                    caught = Sound('res/sfx/camel-caught.wav')}
    sounds.shootArrow = Sound('res/sfx/shoot-arrow.wav')
    sounds.unable = Sound('res/sfx/unable.wav')
    sounds.thud = Sound('res/sfx/thud.wav')
    sounds.pause = Sound('res/sfx/pause.wav')
    sounds.menuSelect = Sound('res/sfx/menu-select.wav')
    sounds.secret = Sound('res/sfx/secret.wav')
    sounds.trap = Sound('res/sfx/trap.wav')

    showDebug = false

    FPS = 15

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
        love.graphics.toggleFullscreen()
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
        elseif key == 'j' then
            jump_to_room(wrapper.game.currentRoom.index + 1)
        elseif key == 'k' then
            jump_to_room(wrapper.game.currentRoom.index - 1)
        elseif key == 'up' or key == 'right' or key == 'down' or
               key == 'left' then
            jump_to_room_in_direction(key)
        elseif key == 'g' then
            -- Give the player some goodies!
            for i = 1, 7 do
                local item = Item('shinything')
                wrapper.game.player:pick_up(item)
            end
        elseif key == 'd' then
            wrapper.game:set_demo_mode(not wrapper.game.demoMode)
            print('demo mode: ', wrapper.game.demoMode)
        elseif key == 'c' then
            for _, c in pairs(wrapper.game.currentRoom:get_characters()) do
                if c.name then
                    c.ai:chase(wrapper.game.player)
                end
            end
        elseif key == 'b' then
            if not wrapper.game.player.armory[bow] then
                local bow = Weapon('bow')
                wrapper.game.player:pick_up(bow)
                bow:add_ammo(20)
            end
        elseif key == 'f' then
            local firestaff = Weapon('firestaff')
            wrapper.game.player:pick_up(firestaff)
        elseif key == 't' then
            local thunderstaff = ThunderStaff()
            wrapper.game.player:pick_up(thunderstaff)
        elseif key == 'h' then
            wrapper.game.player:add_health(100)
        end
    else
        wrapper:keypressed(key)
    end
end

function love.keyreleased(key, unicode)
    wrapper:keyreleased(key)
end

function love.draw()
    --if wrapper.game.player then
    --    sx = ((ROOM_W / 2) - wrapper.game.player.position.x) * .002
    --    sy = ((ROOM_H / 2) - wrapper.game.player.position.y) * .002
    --    love.graphics.shear(sx, sy)
    --end

    wrapper:draw()
end
