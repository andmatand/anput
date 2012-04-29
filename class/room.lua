require('class/fovfinder')
require('class/roombuilder')
require('class/roomfiller')

Room = class('Room')

function Room:init(args)
	self.game = args.game
	self.exits = args.exits
	self.index = args.index

	self.generated = false
	self.visited = false
	self.sprites = {}
	self.turrets = {}
	self.items = {}
	self.requiredObjects = {}
	self.drawn = false
	self.fovCache = {}
	self.messages = {}
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

		-- Clear ownership
		obj.owner = nil

		-- Re-enable animation
		obj.animationEnabled = true
	elseif instanceOf(Brick, obj) then
		table.insert(self.bricks, obj)
	end
end

function Room:add_message(message)
	table.insert(self.messages, message)
end

function Room:character_input()
	for _, c in pairs(self:get_characters()) do
		if not instanceOf(Player, c) then
			c:do_ai()
		end
	end
end

function Room:contains_npc()
	for _, c in pairs(self:get_characters()) do
		if c.name then
			return true
		end
	end

	return false
end

function Room:draw()
	-- If we haven't found the FOV yet
	if not self.fov then
		-- Update the FOV
		self:update_fov()
	end

	-- Draw bricks
	self:draw_bricks()
	
	-- Draw items
	for _, i in pairs(self.items) do
		if tile_occupied(i.position, self.fov) then
			i:draw()
		end
	end

	-- Draw sprites
	for _, s in pairs(self.sprites) do
		if tile_occupied(s.position, self.fov) then
			s:draw()
		end
	end

	-- If there is a message on the queue
	if self.messages[1] then
		-- Draw the message
		self.messages[1]:draw()
	end

	self.drawn = true
end

function Room:draw_bricks()
	if self.game.player.moved or not self.drawn then
		self.lightBrickBatch:bind()
		self.darkBrickBatch:bind()

		-- Clear old bricks
		self.lightBrickBatch:clear()
		self.darkBrickBatch:clear()

		-- Add each brick to the correct spriteBatch
		for _, b in pairs(self.bricks) do
			if tile_occupied(b, self.fov) then
				self.lightBrickBatch:add(b.x * TILE_W * SCALE_X,
				                         b.y * TILE_H * SCALE_Y)
			else
				self.darkBrickBatch:add(b.x * TILE_W * SCALE_X,
				                         b.y * TILE_H * SCALE_Y)
			end
		end

		self.lightBrickBatch:unbind()
		self.darkBrickBatch:unbind()
	end

	love.graphics.setColor(255, 255, 255, DARK)
	love.graphics.draw(self.darkBrickBatch, 0, 0)

	love.graphics.setColor(255, 255, 255, LIGHT)
	love.graphics.draw(self.lightBrickBatch, 0, 0)
end

function Room:erase()
	for _, b in pairs(self.bricks) do
		b:draw()
	end

	for _, i in pairs(self.items) do
		i:erase()
	end

	for _, c in pairs(self:get_characters()) do
		c:erase()
	end

	for _, p in pairs(self.projectiles) do
		p:erase()
	end
end

function Room:find_path(src, dest, characterTeam)
	-- Create a table of the room's occupied nodes
	hotLava = {}
	for _, b in pairs(self.bricks) do
		table.insert(hotLava, {x = b.x, y = b.y})
	end
	for _, c in pairs(self:get_characters()) do
		-- If this character is on the team of the one who called this function
		if c.team == characterTeam then
			table.insert(hotLava, {x = c.position.x, y = c.position.y})
		end
	end

	pf = PathFinder(src, dest, hotLava)
	path = pf:plot()

	-- Remove first node from path
	table.remove(path, 1)

	if #path > 0 then
		return path
	else
		return nil
	end
end

function Room:generate_all()
	repeat until self:generate_next_piece()
end

function Room:generate_next_piece()
	if not self.roomBuilder then
		self.roomBuilder = RoomBuilder(self)
	end

	-- Continue building the walls of the room
	if self.roomBuilder:build_next_piece() then
		if not self.roomFiller then
			self.roomFiller = RoomFiller(self)
		end

		-- Continue filling the room with monsters, items, etc.
		if self.roomFiller:fill_next_step() then
			-- Make a spriteBatch for bricks within the player's FOV
			self.lightBrickBatch = love.graphics.newSpriteBatch(brickImg,
																#self.bricks)

			-- Make a spriteBatch for bricks outside the player's FOV
			self.darkBrickBatch = love.graphics.newSpriteBatch(brickImg,
															   #self.bricks)

			-- Mark the generation process as complete
			self.generated = true

			-- Free up the memory used by the roomBuilder
			self.roomBuilder = nil

			print('generated room ' .. self.index)

			-- Flag that room is generated
			return true
		end
	end

	-- Flag that room is not finished generating
	return false
end

-- Returns a table of all characters in the room
function Room:get_characters()
	local characters = {}

	for _, s in pairs(self.sprites) do
		if instanceOf(Character, s) then
			table.insert(characters, s)
		end
	end

	return characters
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

function Room:get_fov_obstacles()
	return self.bricks
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
			return true
		end

		if not self:tile_walkable({x = x, y = y}) then
			-- Encountered an occupied tile
			return false
		end
	end
end

function Room:remove_sprite(sprite)
	for i, s in pairs(self.sprites) do
		if s == sprite then
			table.remove(self.sprites, i)
			break
		end
	end
end

-- Returns a table of everything within a specified tile
function Room:tile_contents(tile)
	contents = {}

	if tile_offscreen(tile) then
		return nil
	end

	for _, b in pairs(self.bricks) do
		if tiles_overlap(tile, b) then
			-- Nothing can overlap a brick, so return here
			return {b}
		end
	end

	for _, s in pairs(self.sprites) do
		if tiles_overlap(tile, s.position) then
			table.insert(contents, s)
		end
	end

	for _, i in pairs(self.items) do
		if tiles_overlap(tile, i.position) then
			table.insert(contents, i)
		end
	end

	return contents
end

-- Returns true if an item can be safely dropped here
function Room:tile_is_droppoint(tile)
	if (self:tile_in_room(tile) and
	    not tile_occupied(tile, concat_tables({self.bricks,
		                                       self:get_characters(),
		                                       self.items}))) then
		return true
	else
		return false
	end
end

function Room:tile_in_room(tile, options)
	if tile_offscreen(tile) then
		return false
	end

	if tile_occupied(tile, self.freeTiles) then
		return true
	end

	if options and options.includeBricks then
		if tile_occupied(tile, self.bricks) then
			return true
		end
	end
end

-- Return true if tile can be walked on right now (contains no collidable
-- objects)
function Room:tile_walkable(tile)
	-- If the tile is not inside the room, or the tile is occupied by a brick
	if not self:tile_in_room(tile) or tile_occupied(tile, self.bricks) then
		return false
	end

	-- Create a table of collidable characters
	local collidables = {}
	for _, c in pairs(self:get_characters()) do
		-- If this character is corporeal (not a ghost)
		if c.isCorporeal then
			table.insert(collidables, c)
		end
	end

	-- If the tile's position is occupied by that of a collidable sprite
	if tile_occupied(tile, collidables) then
		return false
	end

	return true
end

function Room:update()
	-- Update turrets
	for _, t in pairs(self.turrets) do
		t:update()
	end

	-- Update items
	for _, i in pairs(self.items) do
		i:update()
	end

	-- Update sprites
	for _, s in pairs(self.sprites) do
		-- If this is a character on the good-guy team
		if instanceOf(Character, s) and s.team == 1 then
			-- Recharge HP/ammo
			s:recharge()
		end

		s:update()
	end

	-- Run physics on all sprites
	for _, s in pairs(self.sprites) do
		s:physics()

		-- Check if we the sprite is on an item
		s:check_for_items()
	end
	for _, s in pairs(self.sprites) do
		s:post_physics()
	end

	-- Remove all dead sprites
	local temp = {}
	for _, s in pairs(self.sprites) do
		if not s.dead then
			table.insert(temp, s)
		else
			deadThing = s
		end
	end
	self.sprites = temp

	-- Keep only items that have no owner and have not been used
	local temp = {}
	for _, i in pairs(self.items) do
		if not i.owner and not i.isUsed then
			table.insert(temp, i)
		end
	end
	self.items = temp

	-- Iterate through the room objects which can have mouths
	--for _, o in pairs(self.sprites) do
	--	-- If this object has a mouth which should speak
	--	if o.mouth and o:should_speak() then
	--		o.mouth:speak()
	--	end
	--end

	-- Update messages
	self:update_messages()

	if (self.game.player.moved and
	    self:tile_in_room(self.game.player.position)) then
		self:update_fov()
	end
end

function Room:update_fov()
	-- Check if the player's position is in the FOV cache
	for _, fov in pairs(self.fovCache) do
		if tiles_overlap(fov.origin, self.game.player.position) then
			self.fov = fov.fov

			--print('used cached FOV')
			return
		end
	end

	-- Clear the old FOV
	self.fov = {}

	-- Find player's Field Of View
	fovFinder = FOVFinder({origin = self.game.player.position,
	                       room = self,
	                       radius = 10})
	self.fov = fovFinder:find()

	-- Add this FOV to the FOV cache
	table.insert(self.fovCache, {origin = self.game.player.position,
	                             fov = self.fov})
end

function Room:update_messages()
	-- If there is a message on our queue
	if self.messages[1] then
		self.messages[1]:update()

		-- If the message is finished displaying
		if self.messages[1].finished then
			-- Remove it from the queue
			table.remove(self.messages, 1)
		end
	end
end
