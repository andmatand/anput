require 'class/arrow.lua'
require 'class/roombuilder.lua'
require 'class/roomfiller.lua'

Room = class('Room')

function Room:init(args)
	self.exits = args.exits
	self.index = args.index

	self.generated = false
	self.sprites = {}
	self.turrets = {}
	self.items = {}
end

function Room:add_object(obj)
	if instanceOf(Sprite, obj) then
		-- Add this sprite to the room's sprite table
		table.insert(self.sprites, obj)

		-- Add a reference to this room to the sprite
		obj.room = self
	elseif instanceOf(Turret, obj) then
		-- Add this turret to the room's turret table
		table.insert(self.turrets, obj)

		-- Add a reference to this room to the turret
		obj.room = self
	elseif instanceOf(Item, obj) then
		-- Add this item to the room's item table
		table.insert(self.items, obj)
	end
end

function Room:character_input()
	for i,s in pairs(self.sprites) do
		if instanceOf(Character, s) and not instanceOf(Player, s) then
			s:do_ai()
		end
	end
end

function Room:draw()
	for _,b in pairs(self.bricks) do
		b:draw()
	end

	for _,i in pairs(self.items) do
		i:draw()
	end

	for _,s in pairs(self.sprites) do
		s:draw()
	end
end

function Room:erase()
	for i,b in pairs(self.bricks) do
		b:draw()
	end
	for i,s in pairs(self.sprites) do
		s:erase()
	end
end

function Room:find_path(src, dest)
	pf = PathFinder(src, dest, concat_tables{self.bricks, self.sprites})
	path = pf:plot()

	-- Remove first node from path
	table.remove(path, 1)

	if #path > 0 then
		return path
	else
		return nil
	end
end

function Room:generate()
	-- Build the walls of the room
	rb = RoomBuilder(self.exits)
	rbResults = rb:build()
	self.bricks = rbResults.bricks
	self.freeTiles = rbResults.freeTiles
	self.midPoint = rbResults.midPoint

	-- Fill the room with monsters and items
	rf = RoomFiller(self)
	rf:fill()

	self.generated = true
end

function Room:get_exit(search)
	for i,e in pairs(self.exits) do
		if (e.x ~= nil and e.x == search.x) or
		   (e.y ~= nil and e.y == search.y) or
		   (e.roomIndex ~= nil and e.roomIndex == search.roomIndex) then
			return e
		end
	end
end

function Room:line_of_sight(a, b)
	if tiles_overlap(a, b) then
		return true
	end

	-- Vertical
	if a.x == b.x then
		xDir = 0
		if a.y < b.y then
			yDir = 1
		else
			yDir = -1
		end
	-- Horizontal
	elseif a.y == b.y then
		yDir = 0
		if a.x < b.x then
			xDir = 1
		else
			xDir = -1
		end
	else
		return false
	end

	-- Find any occupied tiles between a and b
	x, y = a.x, a.y
	while true do
		x = x + xDir
		y = y + yDir

		if tiles_overlap({x = x, y = y}, b) then
			-- Reached the destination
			break
		end

		if self:tile_occupied({x = x, y = y}) then
			-- Encountered an occupied tile
			return false
		end
	end

	return true
end


function Room:remove_sprite(sprite)
	for i,s in pairs(self.sprites) do
		if s == sprite then
			table.remove(self.sprites, i)
		end
	end
end

function Room:tile_occupied(tile)
	if tile_occupied(tile, {self.bricks, self.sprites}) or
	   tile_offscreen(tile) then
		return true
	end

	-- Also count exterior tiles as occupied
	occupied = true
	for i,t in pairs(self.freeTiles) do
		if tile.x == t.x and tile.y == t.y then
			occupied = false
			break
		end
	end

	return occupied
end

function Room:update()
	-- Update turrets
	for i,t in pairs(self.turrets) do
		t:update()
	end

	-- Run physics on all sprites
	for i,s in pairs(self.sprites) do
		s:physics()
	end
	--for i,s in pairs(self.sprites) do
	--	s:post_physics()
	--end

	-- Remove all dead sprites
	temp = {}
	for i,s in pairs(self.sprites) do
		if s.dead ~= true then
			table.insert(temp, s)
		end
	end
	self.sprites = temp

	-- Remove all used items
	temp = {}
	for _,i in pairs(self.items) do
		if i.used ~= true then
			table.insert(temp, i)
		end
	end
	self.items = temp
end
