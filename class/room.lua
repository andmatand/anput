require 'class/arrow.lua'
require 'class/roombuilder.lua'

Room = class(SimpleClass)

function Room:init(args)
	self.exits = args.exits
	self.index = args.index

	self.generated = false
	self.sprites = {}

	print('I am a new Room:')
	print('')
end

function Room:add_sprite(sprite)
	table.insert(self.sprites, sprite)
end

function Room:draw()
	for i,b in pairs(self.bricks) do
		b:draw()
	end

	if #self.sprites > 0 then
		for i,s in pairs(self.sprites) do
			s:draw()
		end
	end
end

function Room:erase()
	self:draw()

	for i,s in pairs(self.sprites) do
		s:erase()
	end
end

function Room:generate()
	rb = RoomBuilder(self.exits)
	rbResults = rb:build()
	self.bricks = rbResults.bricks
	self.freeTiles = rbResults.freeTiles
	self.midPoint = rbResults.midPoint

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

function Room:remove_sprite(sprite)
	for i,s in pairs(self.sprites) do
		if s == sprite then
			table.remove(self.sprites, i)
		end
	end
end

function Room:update()
	-- Run physics on all sprites
	for i,s in pairs(self.sprites) do
		s:physics(self.bricks, self.sprites)
	end
	for i,s in pairs(self.sprites) do
		s:post_physics()
	end

	-- Remove all dead sprites
	temp = {}
	for i,s in pairs(self.sprites) do
		if s.dead ~= true then
			table.insert(temp, s)
		end
	end
	self.sprites = temp
end
