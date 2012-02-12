require 'util/oo.lua'
require 'class/game.lua'
require 'class/sound.lua'

function love.load()
	love.graphics.setMode(640, 400, false, false, 0)
	love.mouse.setVisible(false)
	love.graphics.setCaption('TEMPLE OF ANPUT')
	if love.graphics.isCreated() == false then
		print('failed to create a window')
	end

	fontImg = love.graphics.newImage('res/font/screen13.png')
	fontImg:setFilter('nearest', 'nearest')
	font = love.graphics.newImageFont(fontImg,
		'ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789:!"')
	love.graphics.setFont(font)

	playerImg = {love.graphics.newImage('res/img/player1.png')}
	for i,f in pairs(playerImg) do
		f:setFilter('nearest', 'nearest')
	end

	monsterImg = {}
	monsterImg.scarab = {love.graphics.newImage('res/img/scarab1.png'),
	                     love.graphics.newImage('res/img/scarab2.png')}

	monsterImg.bird = {love.graphics.newImage('res/img/bird1.png'),
	                   love.graphics.newImage('res/img/bird2.png')}
	monsterImg.dog = {love.graphics.newImage('res/img/dog.png')}
	for _,m in pairs(monsterImg) do
		for _,i in pairs(m) do
			i:setFilter('nearest', 'nearest')
		end
	end

	arrowImg = love.graphics.newImage('res/img/arrow.png')
	arrowImg:setFilter('nearest', 'nearest')

	potionImg = love.graphics.newImage('res/img/potion.png')
	potionImg:setFilter('nearest', 'nearest')

	playerCrySound = Sound('res/sfx/player-cry.wav')
	playerGetArrowsSound = Sound('res/sfx/player-get-arrows.wav')
	playerGetHPSound = Sound('res/sfx/player-get-hp.wav')
	monsterCrySound = Sound('res/sfx/monster-cry.wav')
	monsterDieSound = Sound('res/sfx/monster-die.wav')

	math.randomseed(os.time())

	TILE_W = 16
	TILE_H = 16
	SCALE_X = 2
	SCALE_Y = 2

	-- Room width and height are in # of tiles (not pixels)
	ROOM_W = 27
	ROOM_H = 25

	camera = {}
	camera.x = 0
	camera.y = 0

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
	elseif key == '1' then
		if showDebug == true then
			showDebug = false
		else
			showDebug = true
		end
	elseif key == '2' then
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
	love.graphics.translate(camera.x, camera.y)

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
