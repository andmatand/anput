require('util.oo')
require('class.sound')
require('class.wrapper')

function cga_print(text, x, y, options)
    -- Set default options
    options = options or {}

    -- If an actual pixel position is given
    if options.position then
        x = options.position.x
        y = options.position.y
    else
        -- Make sure the x and y align to the grid
        x = math.floor(upscale_x(x))
        y = math.floor(upscale_y(y))
    end

    -- Go through each line of the text
    local i = 0
    for line in text:gmatch("[^\n]+") do
        local xPos = x
        if options.center then
            xPos = x - (font:getWidth(line) / 2)
        end

        -- Draw a black background behind this line of text
        love.graphics.setColor(BLACK)
        love.graphics.rectangle('fill', xPos, y + upscale_y(i),
                                font:getWidth(line), font:getHeight())

        -- Set the color
        if options.color then
            love.graphics.setColor(options.color)
        else
            love.graphics.setColor(WHITE)
        end

        -- Draw this line of text
        love.graphics.printf(line, xPos, y + upscale_y(i),
                             font:getWidth(line) + 1, 'center')

        -- Keep track of which line number we're on
        i = i + 1
    end
end

function upscale_x(x)
    return x * TILE_W * SCALE_X
end

function upscale_y(y)
    return y * TILE_H * SCALE_Y
end

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

    -- These are the tile dimensions in pixels
    TILE_W = 8
    TILE_H = 8

    -- These dimensions are in number of tiles (not pixels)
    ROOM_W = 40
    ROOM_H = 24
    SCREEN_W = (love.graphics.getWidth() / upscale_x(1))
    SCREEN_H = (love.graphics.getHeight() / upscale_y(1))

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

    -- Set default image fileter to show ALL the pixels
    love.graphics.setDefaultImageFilter('nearest', 'nearest')

    -- Load the font
    --local fontImg = love.graphics.newImage('res/font/cga.png')
    --local font = love.graphics.newImageFont(fontImg,
    --             'ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789:!"')
    font = love.graphics.newFont('res/font/cga.ttf', TILE_W * SCALE_X)
    love.graphics.setFont(font)

    playerImg = {default = new_image('player.png'),
                 sword = new_image('player-sword.png'),
                 bow = new_image('player-bow.png'),
                 staff = new_image('player-staff.png')}

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

    -- Projectiles
    projectileImg = {}
    projectileImg.arrow = {new_image('arrow.png')}
    projectileImg.fireball = {new_image('fireball1.png'),
                              new_image('fireball2.png')}

    -- Items
    elixirImg = new_image('elixir.png')
    arrowImg = new_image('arrow.png')
    shinyThingImg = {new_image('shiny1.png'),
                     new_image('shiny2.png'),
                     new_image('shiny3.png')}
    swordImg = new_image('sword.png')
    bowImg = new_image('bow.png')
    staffImg = new_image('staff.png')
    ankhImg = new_image('ankh.png')

    -- Verbs
    dropImg = new_image('drop.png')
    useImg = new_image('use.png')

    -- Hieroglyphs
    HIEROGLYPH_IMAGE = {I = new_image('hieroglyphs/I.png'),
                        NP = new_image('hieroglyphs/NP.png'),
                        W = new_image('hieroglyphs/W.png'),
                        T = new_image('hieroglyphs/T.png'),
                        goddess = new_image('hieroglyphs/goddess.png')}

    -- Outside
    outsideImg = {}
    outsideImg.museum = {image = new_image('museum.png'),
                         avatar = new_image('museum-avatar.png')}
    outsideImg.temple = {image = new_image('temple.png')}

    -- Create image data for a brick (a magenta rectangle)
    local brickImgData = love.image.newImageData(upscale_x(1),
                                                 upscale_y(1))
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
        wrapper.game.player:move_to_room(newRoom)
        wrapper.game.player:set_position(newRoom.midPoint)
        wrapper.game:switch_to_room(newRoom)
    end
end

function love.keypressed(key, unicode)
    if key == 'n' and (love.keyboard.isDown('lctrl') or
                       love.keyboard.isDown('rctrl')) then
        wrapper:restart()
    elseif key == 'f11' or
           ((love.keyboard.isDown('ralt') or love.keyboard.isDown('lalt'))
            and key == 'return') then
        love.graphics.toggleFullscreen()
    elseif key == 'q' and (love.keyboard.isDown('lctrl') or
                           love.keyboard.isDown('rctrl')) then
        love.event.quit()
    elseif key == 'f1' then
        DEBUG = not DEBUG
    elseif key == 'j' and love.keyboard.isDown('lctrl') then
        jump_to_room(wrapper.game.currentRoom.index + 1)
    elseif key == 'k' and love.keyboard.isDown('lctrl') then
        jump_to_room(wrapper.game.currentRoom.index - 1)
    elseif key == 'g' and love.keyboard.isDown('lctrl') then
        -- Give the player some goodies!
        for i = 1, 7 do
            local item = Item('shinything')
            wrapper.game.player:pick_up(item)
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
