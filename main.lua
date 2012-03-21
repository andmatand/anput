require('util/oo')
require('class/game')
require('class/sound')

function new_image(filename)
	img = love.graphics.newImage('res/img/' .. filename)
	img:setFilter('nearest', 'nearest')
	return img
end

function tile_print(text, x, y)
	love.graphics.print(text, x * TILE_W, y * TILE_H, 0, SCALE_X, SCALE_Y)
end

function love.conf(t)
	t.modules.joystick = false
	t.modules.mouse = false
	t.modules.physics = false
end

function love.load()
	TILE_W = 16
	TILE_H = 16
	SCALE_X = 2
	SCALE_Y = 2

	-- Room width and height are in # of tiles (not pixels)
	ROOM_W = 27
	ROOM_H = 25
	SCREEN_W = (love.graphics.getWidth() / TILE_W)
	SCREEN_H = (love.graphics.getHeight() / TILE_H)

	love.graphics.setMode(640, 400, false, false, 0)
	love.mouse.setVisible(false)
	love.graphics.setCaption('TEMPLE OF ANPUT')
	if love.graphics.isCreated() == false then
		print('failed to create a window')
	end

	BLACK = {0, 0, 0}
	WHITE = {255, 255, 255}
	CYAN = {85, 255, 255}
	MAGENTA = {255, 0, 255}

	fontImg = love.graphics.newImage('res/font/screen13.png')
	fontImg:setFilter('nearest', 'nearest')
	font = love.graphics.newImageFont(fontImg,
		'ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789:!"')
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
	monsterImg.mummy = {default = new_image('mummy.png'),
	                    moving = new_image('mummy-moving.png')}
	monsterImg.cat = {default = new_image('cat.png'),
	                  moving = new_image('cat-moving.png')}
	monsterImg.ghost = {default = new_image('ghost.png')}

	projectileImg = {}
	projectileImg.arrow = {new_image('arrow.png')}
	projectileImg.fireball = {new_image('fireball1.png'),
	                          new_image('fireball2.png')}

	-- Items
	potionImg = new_image('potion.png')
	arrowsImg = new_image('arrow-item.png')
	shinyThingImg = {new_image('shiny1.png'),
	                 new_image('shiny2.png'),
	                 new_image('shiny3.png')}
	swordImg = new_image('sword.png')
	bowImg = new_image('bow.png')
	staffImg = new_image('staff.png')

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
	sound.playerCry = Sound('res/sfx/player-cry.wav')
	sound.playerGetItem = Sound('res/sfx/player-get-arrows.wav')
	sound.playerGetHP = Sound('res/sfx/player-get-hp.wav')
	sound.switchWeapon = Sound('res/sfx/switch-weapon.wav')
	sound.noAmmo = Sound('res/sfx/no-ammo.wav')
	sound.monsterCry = Sound('res/sfx/monster-cry.wav')
	sound.monsterGetItem = Sound('res/sfx/monster-get-arrows.wav')
	sound.monsterGetHP = Sound('res/sfx/monster-get-hp.wav')
	sound.monsterDie = Sound('res/sfx/monster-die.wav')
	sound.playerDie = Sound('res/sfx/player-die.wav')

	math.randomseed(os.time())

	showDebug = false
	flickerMode = false

	game = Game()
	game:generate()

	fps = 15
	fpsTimer = 0

	--love.keyboard.setKeyRepeat(75, 50)
end

function toggle_flicker_mode()
	if flickerMode == false then
		flickerMode = true
		fps = fps * 2
	else
		flickerMode = false
		fps = fps / 2
	end
end

function love.update(dt)
	-- Limit FPS
	fpsTimer = fpsTimer + dt

	if fpsTimer > 1 / fps then
		game:update()
		fpsTimer = 0
	end
end

function love.keypressed(key, unicode)
	if key == 'n' then
		game = Game()
		game:generate()
	elseif key == 'f1' then
		if showDebug == true then
			showDebug = false
		else
			showDebug = true
		end
	elseif key == 'f2' then
		toggle_flicker_mode()
	elseif key == 'f11' then
		love.graphics.toggleFullscreen()
	end

	game:keypressed(key)

	if key == 'escape' then love.event.push('q') end
end

function love.keyreleased(key, unicode)
	game:keyreleased(key)
end

function love.draw()
	if showDebug then
		-- DEBUG show map obstacles
		for i,o in pairs(game.map.obstacles) do
			love.graphics.setColor(255, 0, 0)
			love.graphics.circle('fill',
								 (o.x * TILE_W) + (TILE_W / 2) - (TILE_W * 5),
								 (o.y * TILE_H) + (TILE_H / 2) - (TILE_H * 5),
			                     3, 10)
		end

		-- DEBUG show map path
		for i,o in pairs(game.map.path) do
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
		for i,o in pairs(game.map.branches) do
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
		--	love.graphics.setColor(255, 0, 0)
		--	love.graphics.circle('fill',
		--						 (o.x * TILE_W) + (TILE_W / 2),
		--						 (o.y * TILE_H) + (TILE_H / 2), 3, 10)
		--end

		---- DEBUG show intermediate points in walls
		--for i,p in pairs(interPoints) do
		--	love.graphics.setColor(0, 0, 255)
		--	love.graphics.circle('fill',
		--						 (p.x * TILE_W) + (TILE_W / 2),
		--						 (p.y * TILE_H) + (TILE_H / 2), 3, 10)
		--end

		---- DEBUG show midPath
		--for i,o in pairs(midPath) do
		--	love.graphics.setColor(255, 255, 255)
		--	love.graphics.circle('fill',
		--						 (o.x * TILE_W) + (TILE_W / 2),
		--						 (o.y * TILE_H) + (TILE_H / 2), 3, 10)
		--end
	end

	game:draw()
end
