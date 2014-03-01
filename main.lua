require('util.oo')
require('class.golem')
require('class.sound')
require('class.wrapper')
require('util.graphics')
require('util.settings')

function love.load()
    love.mouse.setVisible(false)

    load_settings()

    if settings.fullscreen then
        set_fullscreen(true)
    else
        set_scale(SCALE_X, nil, false)
    end

    if love.graphics.isCreated() == false then
        print('failed to create a window')
        love.event.quit()
    end

    GAME_TITLE = 'TEMPLE OF ANPUT'
    love.window.setTitle(GAME_TITLE)

    -- Set the width and height of the tile grid (in # of tiles)
    GRID_W = BASE_SCREEN_W / TILE_W
    GRID_H = BASE_SCREEN_H / TILE_H

    -- These dimensions are in number of tiles (not pixels)
    ROOM_W = GRID_W
    ROOM_H = GRID_H - 1

    -- Colors
    BLACK = {0, 0, 0}
    WHITE = {255, 255, 255}
    CYAN = {85, 255, 255}
    MAGENTA = {255, 85, 255}

    -- Alpha values
    LIGHT = 255
    DARK = 15

    FPS_LIMIT = 15

    -- Create a new wrapper object
    wrapper = Wrapper()
end

function love.focus(focus)
    if not focus then
        wrapper:pause()
    end
end

function love.update(dt)
    wrapper:update(dt)
end

function jump_to_room(index)
    if index >= 1 and index <= #wrapper.game.rooms then
        local newRoom = wrapper.game.rooms[index]
        wrapper.game:switch_to_room(newRoom)
        wrapper.game.player:move_to_room(newRoom)
        wrapper.game.player:set_position(newRoom.midPoint)
    end
end

function translate_direction(direction)
    if type(direction) == 'string' then
        if direction == 'up' then
            return 1
        elseif direction == 'right' then
            return 2
        elseif direction == 'down' then
            return 3
        elseif direction == 'left' then
            return 4
        end
    end
end

function jump_to_room_in_direction(direction)
    local currentNode

    -- Find the current room's map node
    for _, n in pairs(wrapper.game.map.nodes) do
        if n.room == wrapper.game.currentRoom then
            currentNode = n
            break
        end
    end

    -- Find the target position
    local dir = translate_direction(direction)
    local targetPos = add_direction(currentNode, dir)

    -- Find the node that overlaps with the target position
    for _, n in pairs(wrapper.game.map.nodes) do
        if tiles_overlap(n, targetPos) then
            jump_to_room(n.room.index)
            return
        end
    end
end

function love.joystickadded(joystick)
    wrapper:joystick_added(joystick)
end

function love.gamepadpressed(joystick, button)
    wrapper:gamepad_pressed(joystick, button)
    --gamepadButton = button
end

function love.gamepadreleased(joystick, button)
    wrapper:gamepad_released(joystick, button)
end

function love.joystickremoved(joystick)
    wrapper:joystick_removed(joystick)
end

function love.keypressed(key, unicode)
    local ctrl, shift
    if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
        ctrl = true
    end
    if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
        shift = true
    end

    if ctrl and key == 'n' then
        wrapper:restart()
    elseif key == 'f11' or
           ((love.keyboard.isDown('ralt') or love.keyboard.isDown('lalt'))
            and key == 'return') then
        toggle_fullscreen()
    elseif ctrl and key == 'q' then
        save_settings()
        love.event.quit()
    elseif ctrl and (key == '=' or key == '+') then
        if (SCALE_X < 5) then
            set_scale(SCALE_X + 1)
        end
    elseif ctrl and key == '-' then
        set_scale(SCALE_X - 1)

    elseif ctrl and shift then
        if key == 'f1' then
            DEBUG = not DEBUG
            wrapper.game.currentRoom.bricksDirty = true
        end

        -- DEBUG commands
        if DEBUG then
            if key == 'i' then
                wrapper.game.player.isInvincible =
                    not wrapper.game.player.isInvincible
            elseif key == 'j' then
                jump_to_room(wrapper.game.currentRoom.index + 1)
            elseif key == 'k' then
                jump_to_room(wrapper.game.currentRoom.index - 1)
            elseif key == 'up' or key == 'right' or key == 'down' or
                   key == 'left' then
                jump_to_room_in_direction(key)
            elseif key == 'a' then
                local artifact = Item('ankh')
                wrapper.game.player:pick_up(artifact)
            elseif key == 'b' then
                if not wrapper.game.player.armory.weapons.bow then
                    local bow = Weapon('bow')
                    wrapper.game.player:pick_up(bow)
                end
                wrapper.game.player.armory.weapons.bow:add_ammo(20)
            elseif key == 'c' then
                local camel = Camel()
                camel.state = 'caught'
                camel.ai.level.globetrot.prob = nil
                camel.isCaught = true
                camel.ai.level.follow.prob = 10
                camel.ai.level.follow.target = wrapper.game.player
                camel:set_position(wrapper.game.currentRoom:get_free_tile())
                wrapper.game.currentRoom:add_object(camel)
            elseif key == 'd' then
                wrapper.game:set_demo_mode(not wrapper.game.demoMode)
                print('demo mode: ', wrapper.game.demoMode)
            elseif key == 'e' then
                local elixir = Item('elixir')
                wrapper.game.player:pick_up(elixir)
            elseif key == 'f' then
                local firestaff = Weapon('firestaff')
                wrapper.game.player:pick_up(firestaff)
            elseif key == 'g' then
                -- Give the player some goodies!
                for i = 1, 7 do
                    local item = Item('shinything')
                    wrapper.game.player:pick_up(item)
                end
            elseif key == 'h' then
                wrapper.game.player:add_health(100)
            elseif key == 'o' then
                local horn = Horn()
                wrapper.game.player:pick_up(horn)
            elseif key == 'p' then
                local potion = Item('potion')
                wrapper.game.player:pick_up(potion)
            elseif key == 's' then
                if wrapper.game.currentRoom then
                    for _, spike in pairs(wrapper.game.currentRoom.spikes) do
                        spike:trigger()
                    end
                end
            elseif key == 't' then
                local thunderstaff = ThunderStaff()
                wrapper.game.player:pick_up(thunderstaff)
            elseif key == 'z' then
                wrapper.game.player:receive_damage(100, wrapper.game.player)
            end
        end
    else
        wrapper:key_pressed(key)
    end
end

function love.keyreleased(key, unicode)
    wrapper:key_released(key)
end

function love.draw()
    --if wrapper.game.player then
    --    sx = ((ROOM_W / 2) - wrapper.game.player.position.x) * .002
    --    sy = ((ROOM_H / 2) - wrapper.game.player.position.y) * .002
    --    love.graphics.shear(sx, sy)
    --end

    love.graphics.setScissor(SCREEN_X, SCREEN_Y,
                             BASE_SCREEN_W * SCALE_X, BASE_SCREEN_H * SCALE_Y)
    love.graphics.translate(SCREEN_X, SCREEN_Y)

    if DEBUG and wrapper.game.player then
        local pos = wrapper.game.player:get_position()
        cga_print(pos.x .. ' ' .. pos.y, 1, 1)
    end

    wrapper:draw()

    love.graphics.setScissor()

    --if gamepadButton then
    --    cga_print(gamepadButton:upper(), 1, 1)
    --end
    --if wrapper.game.player then
    --    local txt = wrapper.game.player.position.x .. ' ' ..
    --                wrapper.game.player.position.y
    --    cga_print(txt, 1, 1)
    --end
end

-- Returns distance between two tiles
function distance(a, b)
    return math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
end
