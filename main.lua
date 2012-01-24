require 'class/arrow.lua'
require 'class/turret.lua'
require 'class/brick.lua'
require 'class/exit.lua'
require 'class/room.lua'

function love.load()
	love.graphics.setMode(640, 400, false, false, 0)
	math.randomseed(os.time())

	TILE_W = 16
	TILE_H = 16

	-- Room width and height are in # of tiles (not pixels)
	ROOM_W = 27
	ROOM_H = 25

	-- TEMP: make some statically-positioned exits
	exits = {Exit:new(ROOM_W, 14), Exit:new(1, -1), Exit:new(4, ROOM_H)}

	room = Room:new(exits)
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
		room = Room:new(exits)
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
