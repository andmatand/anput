require('love.filesystem')
require('util.oo')
require('class.exit')
require('class.roombuilder')

ROOM_W = 40
ROOM_H = 24

-- The roombuilder thread returns a pseudo-room object with bricks when given a
-- pseudo-room object with exits

function parse_room(string)
    -- Load the message as Lua code
    local chunk, errorMsg = loadstring(string)
    local room = chunk()

    return room
end

function serialize_room(room)
    local msg = ''

    msg = msg .. 'local room = {}\n'
    msg = msg .. 'room.randomSeed = ' .. room.randomSeed .. '\n'
    msg = msg .. 'room.index = ' .. room.index .. '\n'

    --msg = msg .. 'room.exits = {}\n'
    --for _, e in pairs(room.exits) do
    --    msg = msg .. 'table.insert(room.exits, Exit({x = ' .. e.x .. ', ' ..
    --                                                'y = ' .. e.y .. '}))'
    --    msg = msg .. '\n'
    --end

    msg = msg .. 'room.bricks = {}\n'

    for _, b in pairs(room.bricks) do
        msg = msg .. 'newBrick = Brick({x = ' .. b.x .. ', ' ..
                                       'y = ' .. b.y .. '})' .. '\n'
        if b.fromWall then
            msg = msg .. 'newBrick.fromWall = ' .. b.fromWall .. '\n'
        end
        msg = msg .. 'table.insert(room.bricks, newBrick)' .. '\n'
    end

    msg = msg .. 'room.freeTiles = {}\n'
    for _, t in pairs(room.freeTiles) do
        msg = msg .. 'table.insert(room.freeTiles, {x = ' .. t.x .. ', ' ..
                                                   'y = ' .. t.y .. '})'
        msg = msg .. '\n'
    end

    msg = msg .. 'room.zoneTiles = {}\n'
    for _, t in pairs(room.zoneTiles) do
        msg = msg .. 'table.insert(room.zoneTiles, {x = ' .. t.x .. ', ' ..
                                                   'y = ' .. t.y .. '})'
        msg = msg .. '\n'
    end

    msg = msg .. 'room.midPoint = {x = ' .. room.midPoint.x .. ', ' ..
                                  'y = ' .. room.midPoint.y .. '}\n'

    msg = msg .. 'room.midPaths = {}\n'
    for _, t in pairs(room.midPaths) do
        msg = msg .. 'table.insert(room.midPaths, {x = ' .. t.x .. ', ' ..
                                                  'y = ' .. t.y .. '})'
        msg = msg .. '\n'
    end

    msg = msg .. 'room.lakes = {}\n'
    for _, lake in pairs(room.lakes) do
        msg = msg .. 'tiles = {}\n'
        for _, t in pairs(lake.tiles) do
            msg = msg .. 'table.insert(tiles, {x = ' .. t.x .. ', ' ..
                                              'y = ' .. t.y .. '})\n'
        end

        msg = msg .. 'table.insert(room.lakes, Lake(tiles))\n'
    end

    msg = msg .. 'room.nooks = {}\n'
    for _, nook in pairs(room.nooks) do
        msg = msg .. 'tiles = {}\n'
        for _, t in pairs(nook) do
            msg = msg .. 'table.insert(tiles, {x = ' .. t.x .. ', ' ..
                                              'y = ' .. t.y .. '})\n'
        end

        msg = msg .. 'table.insert(room.nooks, tiles)\n'
    end

    msg = msg .. 'return room'

    return msg
end

-- Get references to the existing roombuilder channels (created in wrapper.lua)
local inputChannel = love.thread.getChannel('roombuilder_input')
local outputChannel = love.thread.getChannel('roombuilder_output')

while true do
    -- Wait for a message containing a pseudo room object
    local input = inputChannel:demand()

    -- Create a pseudo room object
    local room = parse_room(input)
    
    -- Create a roombuilder object
    local roomBuilder = RoomBuilder(room)
    roomBuilder.isInThread = true

    -- Try buidling the room
    if roomBuilder:build() then
        -- Convert the pseudo room object to a string of Lua code
        local output = serialize_room(room)

        -- Send the pseudo room object as a message back to the main thread
        outputChannel:push(output)
    end
end
