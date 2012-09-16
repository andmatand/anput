require('util.oo')
require('class.sound')
require('class.wrapper')
require('util.graphics')

function serialize_room(room)
    local msg = ''
    msg = msg .. 'local room = {}\n'
    msg = msg .. 'room.randomSeed = ' .. room.randomSeed .. '\n'
    msg = msg .. 'room.index = ' .. room.index .. '\n'
    if room.needsSpaceForNPC then
        msg = msg .. 'room.needsSpaceForNPC = true\n'
    end

    msg = msg .. 'room.exits = {}\n'
    for _, e in pairs(room.exits) do
        msg = msg .. 'table.insert(room.exits, Exit({x = ' .. e.x .. ', ' ..
                                                    'y = ' .. e.y .. '}))'
        msg = msg .. '\n'
    end
    msg = msg .. 'return room'

    return msg
end

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
    monsterImg = {}
    monsterImg.scarab = {default = new_image('scarab.png'),
                         walk = new_image('scarab-walk.png')}
    monsterImg.bird = {default = new_image('bird.png'),
                       dodge = new_image('bird-dodge.png'),
                       walk = new_image('bird-walk.png')}
    monsterImg.cat = {default = new_image('cat.png'),
                      walk = new_image('cat-walk.png')}
    monsterImg.mummy = {default = new_image('mummy.png'),
                        walk = new_image('mummy-walk.png')}
    monsterImg.archer = {bow = new_image('archer-bow.png'),
                         --bow_shoot = new_image('archer-shoot.png'),
                         sword = new_image('archer-sword.png')}
    monsterImg.ghost = {default = new_image('ghost.png')}

    -- NPCs
    camelImg = {default = new_image('camel.png'),
                step = new_image('camel-step.png')}

    -- Projectiles
    projectileImg = {}
    projectileImg.arrow = {new_image('item/arrow.png')}
    projectileImg.fireball = {new_image('fireball1.png'),
                              new_image('fireball2.png')}

    -- Items
    images.ankh = new_image('item/ankh.png')
    images.elixir = new_image('item/elixir.png')
    images.arrow = new_image('item/arrow.png')
    images.shinything = {new_image('item/shiny-1.png'),
                         new_image('item/shiny-2.png'),
                         new_image('item/shiny-3.png')}
    images.sword = new_image('weapon/sword.png')
    images.bow = new_image('weapon/bow.png')
    images.firestaff = new_image('weapon/firestaff.png')
    images.thunderstaff = new_image('weapon/thunderstaff.png')

    -- Verbs
    dropImg = new_image('drop.png')
    useImg = new_image('use.png')

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
    sound = {}
    sound.theme = Sound('res/sfx/theme.wav')
    sound.playerCry = Sound('res/sfx/player-cry.wav')
    sound.playerGetItem = Sound('res/sfx/player-get-item.wav')
    sound.playerDropItem = Sound('res/sfx/player-drop-item.wav')
    sound.playerGetHP = Sound('res/sfx/player-get-hp.wav')
    sound.monsterCry = Sound('res/sfx/monster-cry.wav')
    sound.monsterGetItem = Sound('res/sfx/monster-get-item.wav')
    sound.monsterGetHP = Sound('res/sfx/monster-get-hp.wav')
    sound.monsterDie = Sound('res/sfx/monster-die.wav')
    sound.playerDie = Sound('res/sfx/player-die.wav')
    sound.shootArrow = Sound('res/sfx/shoot-arrow.wav')
    sound.unable = Sound('res/sfx/unable.wav')
    sound.pause = Sound('res/sfx/pause.wav')
    sound.menuSelect = Sound('res/sfx/menu-select.wav')
    sound.secret = Sound('res/sfx/secret.wav')
    sound.trap = Sound('res/sfx/trap.wav')

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
        elseif key == 'f' then
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

    if false then
        -- DEBUG show map obstacles
        for _,o in pairs(game.map.obstacles) do
            love.graphics.setColor(255, 0, 0)
            love.graphics.circle('fill',
                                 (o.x * TILE_W) + (TILE_W / 2) - (TILE_W * 5),
                                 (o.y * TILE_H) + (TILE_H / 2) - (TILE_H * 5),
                                 3, 10)
        end

        -- DEBUG show map path
        for _,o in pairs(game.map.path) do
            if o.room.index == game.currentRoom.index then
                love.graphics.setColor(255, 255, 255)
            else
                love.graphics.setColor(0, 255, 0)
            end
            love.graphics.circle('fill',
                                 (o.x * TILE_W) + (TILE_W / 2) - (TILE_W * 5),
                                 (o.y * TILE_H) + (TILE_H / 2) - (TILE_H * 5),
                                 3, 10)
        end

        -- DEBUG show map branches
        for _,o in pairs(game.map.branches) do
            if o.room.index == game.currentRoom.index then
                love.graphics.setColor(255, 255, 255)
            else
                love.graphics.setColor(0, 255, 0)
            end
            love.graphics.setColor(0, 0, 255)
            love.graphics.rectangle('fill',
                                    (o.x * TILE_W) - (TILE_W * 5),
                                    (o.y * TILE_H) - (TILE_H * 5),
                                    TILE_W, TILE_H)
        end

        -- DEBUG: show obstacles
        --for i,o in pairs(globalObstacles) do
        --  love.graphics.setColor(255, 0, 0)
        --  love.graphics.circle('fill',
        --                       (o.x * TILE_W) + (TILE_W / 2),
        --                       (o.y * TILE_H) + (TILE_H / 2), 3, 10)
        --end

        ---- DEBUG show intermediate points in walls
        --for i,p in pairs(interPoints) do
        --  love.graphics.setColor(0, 0, 255)
        --  love.graphics.circle('fill',
        --                       (p.x * TILE_W) + (TILE_W / 2),
        --                       (p.y * TILE_H) + (TILE_H / 2), 3, 10)
        --end

    end

    wrapper:draw()
end
