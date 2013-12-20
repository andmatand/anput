function load_assets()
    if LOADED_ASSETS then return end
    local loadTimeStart = love.timer.getTime()

    -- Shorthand Functions
    local function new_image(filename)
        local img = love.graphics.newImage('res/img/' .. filename)
        --img:setfilter('nearest', 'nearest')
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

    -- Player Images
    playerImg = {default = new_image('player.png'),
                 sword = new_image('player-sword.png'),
                 bow = new_image('player-bow.png'),
                 horn = new_image('player-horn.png'),
                 firestaff = new_image('player-firestaff.png'),
                 thunderstaff = new_image('player-thunderstaff.png')}

    -- Monster Images
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

    -- Outside Images
    outsideImg = {}
    outsideImg.museum = {image = new_image('museum.png'),
                         avatar = new_image('museum-avatar.png')}
    outsideImg.temple = {image = new_image('temple.png')}

    -- Sounds
    sounds = {}
    sounds.theme = Sound('res/sfx/theme.wav')
    sounds.door = {open1 = Sound('res/sfx/door-open1.wav'),
                   open2 = Sound('res/sfx/door-open2.wav'),
                   open3 = Sound('res/sfx/door-open3.wav'),
                   open4 = Sound('res/sfx/door-open4.wav'),
                   open5 = Sound('res/sfx/door-open5.wav')}
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

    LOADED_ASSETS = true
    print('loaded assets in ' .. love.timer.getTime() - loadTimeStart)
end
