require('util/oo')
require('class/exit')
require('class/roombuilder')
require('class/roomfiller')

ROOM_W = 40
ROOM_H = 24

-- The roombuilder thread returns a pseudo-room object with bricks when given a
-- pseudo-room object with exits
thread = love.thread.getThread('roombuilder_thread')

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

    msg = msg .. 'room.exits = {}\n'
    for _, e in pairs(room.exits) do
        msg = msg .. 'table.insert(room.exits, Exit({x = ' .. e.x .. ', ' ..
                                                    'y = ' .. e.y .. '}))'
        msg = msg .. '\n'
    end

    msg = msg .. 'room.bricks = {}\n'
    for _, b in pairs(room.bricks) do
        msg = msg .. 'table.insert(room.bricks, Brick({x = ' .. b.x .. ', ' ..
                                                      'y = ' .. b.y .. '}))'
        msg = msg .. '\n'
    end

    msg = msg .. 'room.freeTiles = {}\n'
    for _, t in pairs(room.freeTiles) do
        msg = msg .. 'table.insert(room.freeTiles, {x = ' .. t.x .. ', ' ..
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

    msg = msg .. 'return room'

    return msg
end

while true do
    -- Wait for a message containing a pseudo room object
    local input = thread:demand('input')

    -- Create a fake room object
    local room = parse_room(input)
    
    -- Create a roombuilder object
    local roomBuilder = RoomBuilder(room)

    -- Try buidling the room
    if roomBuilder:build() then
        -- Create a roomfiller object
        --local roomFiller = RoomFiller(room)
        --roomFiller:add_turrets()

        -- Convert the pseudo room object to a string of Lua code, and set it
        -- as -- our message
        local output = serialize_room(room)
        thread:set('result', output)
    end
end
