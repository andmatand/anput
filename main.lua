require('util.oo')
require('class.game')
require('class.sound')

function new_image(filename)
    img = love.graphics.newImage('res/img/' .. filename)
    --img:setFilter('nearest', 'nearest')
    return img
end

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

function manage_roombuilder_thread()
    -- Check the brick_layer thread for a message containing a pseudo-room
    -- object
    local result = roombuilder_thread:get('result')

    -- If we got a message
    if result then
        --print('got result from thread!')
        -- Execute the string as Lua code
        local chunk = loadstring(result)
        local room = chunk()

        local roomIsFromThisGame = true

        -- Find the real room that has the same index
        local realRoom = game.rooms[room.index]

        if realRoom then
            if room.randomSeed ~= realRoom.randomSeed then
                -- Room-specific random seed does not match
                roomIsFromThisGame = false
            else
                for i, e in ipairs(room.exits) do
                    if not tiles_overlap(e:get_position(),
                                         realRoom.exits[i]:get_position()) then
                        -- All exits do not match
                        roomIsFromThisGame = false
                        break
                    end
                end
            end
        else
            roomIsFromThisGame = false
        end

        if roomIsFromThisGame then
            -- Attach psuedo room's member variables to the real room
            for k, v in pairs(room) do
                if k ~= 'exits' then
                    realRoom[k] = v
                end
            end
            realRoom.isBuilt = true
            realRoom.isBeingBuilt = false
        else
            print('rejected room built for previous game')
        end
    end

    -- If the roombuilder thread does not have any input message
    if not roombuilder_thread:peek('input') then
        -- Find the next room that is not built or being built
        local nextRoom = nil
        for _, r in pairs(game:get_adjacent_rooms()) do
            if not r.isBuilt and not r.isBeingBuilt then
                nextRoom = r
                break
            end
        end
        if not nextRoom then
            for _, r in pairs(game.rooms) do
                if not r.isBuilt and not r.isBeingBuilt then
                    nextRoom = r
                    break
                end
            end
        end

        if nextRoom then
            nextRoom.isBeingBuilt = true

            -- Send another pseduo-room message
            local input = serialize_room(nextRoom)
            roombuilder_thread:set('input', input)
        end
    end
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
                         moving = new_image('scarab-moving.png')}
    monsterImg.bird = {default = new_image('bird.png'),
                       dodge = new_image('bird-dodge.png')}
    monsterImg.cat = {default = new_image('cat.png'),
                      moving = new_image('cat-moving.png')}
    monsterImg.mummy = {default = new_image('mummy.png'),
                        moving = new_image('mummy-moving.png')}
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
    fpsTimer = 0

    game = Game()
    game:generate()

    -- Create a new thread for building rooms' walls
    roombuilder_thread = love.thread.newThread('roombuilder_thread',
                                               'thread/roombuilder.lua')
    roombuilder_thread:start()
end

function love.update(dt)
    -- Limit FPS
    fpsTimer = fpsTimer + dt

    game:add_time(dt)

    if fpsTimer > 1 / FPS then
        game:update()

        --game.player.health = 100
        --if not game.player.armory.sword then
        --    local sword = Weapon('sword')
        --    game.player:pick_up(sword)
        --end

        fpsTimer = 0
    else
        manage_roombuilder_thread()

        --if fpsTimer < (1 / FPS) / 4 then
            for _, r in pairs(game.rooms) do
                if r.isBuilt and not r.isGenerated then
                    r:generate_next_piece()
                end
            end
        --end
    end
end

function love.keypressed(key, unicode)
    if key == 'n' and (love.keyboard.isDown('lctrl') or
                       love.keyboard.isDown('rctrl')) then
        game = Game()
        game:generate()
    elseif key == 'f11' or
           ((love.keyboard.isDown('ralt') or love.keyboard.isDown('lalt'))
            and key == 'return') then
        love.graphics.toggleFullscreen()
    elseif key == 'q' and (love.keyboard.isDown('lctrl') or
                           love.keyboard.isDown('rctrl')) then
        love.event.quit()
    elseif key == 'f1' then
        DEBUG = not DEBUG
    else
        game:keypressed(key)
    end
end

function love.keyreleased(key, unicode)
    game:keyreleased(key)
end

function love.draw()
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

    if game then
        game:draw()
    end
end
