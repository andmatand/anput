require 'util/oo.lua'
require 'util/tile.lua'
require 'class/game.lua'

function distance(a, b)
	return math.sqrt( (b.x - a.x)^2 + (b.y - a.y)^2 )
end

function love.load()
	love.graphics.setMode(640, 400, false, false, 0)
	playerImg = love.graphics.newImage('res/img/player.png')
	playerImg:setFilter('nearest', 'nearest')

	arrowImg = love.graphics.newImage('res/img/arrow.png')
	arrowImg:setFilter('nearest', 'nearest')

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
	end

	game:keypressed(key)
	--if key == 'up' then
	--	camera.y = camera.y + TILE_H
	--elseif key == 'down' then
	--	camera.y = camera.y - TILE_H
	--elseif key == 'left' then
	--	camera.x = camera.x + TILE_W
	--elseif key == 'right' then
	--	camera.x = camera.x - TILE_W
	--end

	if key == 'escape' then love.event.push('q') end
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
