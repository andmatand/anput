--require 'class/exit.lua'
--require 'class/room.lua'
require 'class/map.lua'

function distance(a, b)
	return math.sqrt( (b.x - a.x)^2 + (b.y - a.y)^2 )
end

function random_exits()
	-- DEBUG: Make some random exits
	exits = {}
	while #exits == 0 do
		for i = 1,math.random(1,4) do
			x = math.random(2, ROOM_W - 2)
			y = math.random(2, ROOM_H - 2)

			wall = math.random(1, 4)
			if wall == 1 then
				y = -1 -- North
			elseif wall == 2 then
				x = ROOM_W -- East
			elseif wall == 3 then
				y = ROOM_H -- South
			elseif wall == 4 then
				x = -1 -- West
			end

			-- Make sure it's not too close to another exit
			ok = true
			for j,e in pairs(exits) do
				if distance({x = x, y = y}, e) < 4 then
					ok = false
					break
				end
			end

			if ok then
				print('making exit...')
				table.insert(exits, Exit:new(x, y))
			end
		end
	end

	return exits
end

function generate_random_level()
	-- DEBUG
	globalObstacles = {}
	midPath = {}
	interPoints = {}

	room = Room:new(random_exits())
	room:generate()
	wallNum = 1
end

function new_map()
	mapPath = {}
	map = Map:new()
	map:generate()
end

function love.load()
	love.graphics.setMode(640, 400, false, false, 0)
	math.randomseed(os.time())

	TILE_W = 8
	TILE_H = 8

	-- Room width and height are in # of tiles (not pixels)
	ROOM_W = 27
	ROOM_H = 25


	--exits = {Exit:new(ROOM_W, 14), Exit:new(1, -1), Exit:new(4, ROOM_H)}
	--exits = {Exit:new(ROOM_W, 2), Exit:new(ROOM_W, 15)}
	
	camera = {}
	camera.x = 0
	camera.y = 0
	new_map()

	showDebug = true
end

function love.update(dt)
	--game:updateRoom()
end

function love.keypressed(key, unicode)
	if key == 'a' then
		--generate_random_level()
		new_map()
	elseif key == 'd' then
		if showDebug == true then
			showDebug = false
		else
			showDebug = true
		end
	end

	if key == 'up' then
		camera.y = camera.y + TILE_H
	elseif key == 'down' then
		camera.y = camera.y - TILE_H
	elseif key == 'left' then
		camera.x = camera.x + TILE_W
	elseif key == 'right' then
		camera.x = camera.x - TILE_W
	end

	--if key == 'up' then
	--	playerY = playerY - playerH
	--elseif key == 'down' then
	--	playerY = playerY + playerH
	--elseif key == 'left' then
	--	playerX = playerX - playerW
	--elseif key == 'right' then
	--	playerX = playerX + playerW
	--end

	if key == 'escape' then love.event.push('q') end
end

function love.draw()
	love.graphics.scale(2, 2)
	love.graphics.translate(camera.x, camera.y)
	--room:draw()
	--love.timer.sleep(25)
	--wallNum = wallNum + 1

	if showDebug then
		-- DEBUG show map obstacles
		for i,o in pairs(map.obstacles) do
			love.graphics.setColor(255, 0, 0)
			love.graphics.circle('fill',
								 (o.x * TILE_W) + (TILE_W / 2),
								 (o.y * TILE_H) + (TILE_H / 2),
			                     3, 10)
		end

		-- DEBUG show map path
		for i,o in pairs(map.path) do
			love.graphics.setColor(0, 255, 0)
			love.graphics.circle('fill',
								 (o.x * TILE_W) + (TILE_W / 2),
								 (o.y * TILE_H) + (TILE_H / 2),
			                     3, 10)
		end

		-- DEBUG show map branches
		for i,o in pairs(map.branches) do
			love.graphics.setColor(0, 0, 255)
			love.graphics.rectangle('fill',
				(o.x * TILE_W), (o.y * TILE_H), TILE_W, TILE_H)
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

end

-- Returns size of table
function len(t)
	num = 0
	for i,p in pairs(t) do
		num = i
	end

	return num
end
