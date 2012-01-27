require 'class/arrow.lua'
require 'class/turret.lua'
require 'class/brick.lua'
require 'class/exit.lua'
require 'class/room.lua'

local function distance(a, b)
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

function love.load()
	love.graphics.setMode(640, 400, false, false, 0)
	math.randomseed(os.time())

	TILE_W = 16
	TILE_H = 16

	-- Room width and height are in # of tiles (not pixels)
	ROOM_W = 27
	ROOM_H = 25


	--exits = {Exit:new(ROOM_W, 14), Exit:new(1, -1), Exit:new(4, ROOM_H)}
	--exits = {Exit:new(ROOM_W, 2), Exit:new(ROOM_W, 15)}

	room = Room:new(random_exits())
	room:generate()
	wallNum = 1

	playerX = 5
	playerY = 5
end

function love.update(dt)
	--game:updateRoom()
end

function love.keypressed(key, unicode)
	if key == 'a' then
		room = Room:new(random_exits())
		room:generate()
		wallNum = 1
	end

	if key == 'up' then
		playerY = playerY - playerH
	elseif key == 'down' then
		playerY = playerY + playerH
	elseif key == 'left' then
		playerX = playerX - playerW
	elseif key == 'right' then
		playerX = playerX + playerW
	end

	if key == 'escape' then love.event.push('q') end
end

function love.draw()
	room:draw()
	--love.timer.sleep(25)
	wallNum = wallNum + 1
end

-- Returns size of table
function len(t)
	num = 0
	for i,p in pairs(t) do
		num = i
	end

	return num
end
