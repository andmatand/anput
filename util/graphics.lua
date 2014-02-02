function bresenham_line(x0, y0, x1, y1)
    local x0 = x0
    local y0 = y0
    local x1 = x1
    local y1 = y1

    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx, sy
    if x0 < x1 then sx = 1 else sx = -1 end
    if y0 < y1 then sy = 1 else sy = -1 end
    local err = dx - dy

    local loop = true
    while loop do
       love.graphics.rectangle('fill',
                               x0 * SCALE_X, y0 * SCALE_Y,
                               SCALE_X, SCALE_Y)
       if x0 == x1 and y0 == y1 then
           loop = false
       end
       local e2 = 2 * err
       if e2 > -dy then
           err = err - dy
           x0 = x0 + sx
       end
       if e2 < dx then
           err = err + dx
           y0 = y0 + sy
       end
    end
end

function cga_print(text, x, y, options)
    -- Set default options
    options = options or {}

    local x, y = x, y
    local text = tostring(text)

    -- If an actual pixel position is given
    if options.position then
        x = options.position.x
        y = options.position.y
    else
        -- Make sure the x and y align to the grid
        x = math.floor(upscale_x(x))
        y = math.floor(upscale_y(y))
    end

    -- Go through each line of the text
    local i = 0
    for line in text:gmatch("[^\n]+") do
        local xPos = x
        if options.center then
            xPos = x - ((font:getWidth(line) * SCALE_X) / 2)
        end

        -- Draw a black background behind this line of text
        love.graphics.setColor(BLACK)
        love.graphics.rectangle('fill', xPos, y + upscale_y(i),
                                SCALE_X * font:getWidth(line),
                                font:getHeight() * SCALE_Y)

        -- Set the color
        if options.color then
            love.graphics.setColor(options.color)
        else
            love.graphics.setColor(WHITE)
        end

        -- Draw this line of text
        love.graphics.print(line, xPos, y + upscale_y(i), 0, SCALE_X, SCALE_Y)

        -- Keep track of which line number we're on
        i = i + 1
    end
end

-- Parameters refer to the size of the content area, not the actual border
function draw_border(x, y, w, h)
    love.graphics.setColor(WHITE)
    love.graphics.rectangle('fill',
                            upscale_x(x - 1), upscale_y(y -1),
                            upscale_x(w + 2), upscale_y(h + 2))
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            upscale_x(x), upscale_y(y),
                            upscale_x(w), upscale_y(h))
end

function draw_progress_bar(barInfo, x, y, w, h)
    bar = {}
    bar.x = x + SCALE_X
    bar.y = y + SCALE_Y
    bar.w = w - (SCALE_X * 2)
    bar.h = h - (SCALE_Y * 2)
    
    -- Draw border
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle('rough')
    love.graphics.setColor(barInfo.borderColor or WHITE)
    love.graphics.rectangle('fill', x, y, w, h)

    -- Draw black bar inside
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)

    -- Set width of bar
    bar.w = (barInfo.num * bar.w) / barInfo.max
    bar.w = math.floor(bar.w / SCALE_X) * SCALE_X

    -- Draw progress bar
    love.graphics.setColor(barInfo.color)
    love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)
end

function get_rotation(dir)
    local r = 0
    local sx = SCALE_X
    local sy = SCALE_Y
    if dir == 2 then
        r = math.rad(90)
    elseif dir == 3 then
        sy = -SCALE_Y
    elseif dir == 4 then
        r = math.rad(90)
        sy = -SCALE_Y
    end

    return r, sx, sy
end

function toggle_fullscreen()
    local w, h, flags = love.window.getMode()

    -- If we are already in fullscreen
    if flags.fullscreen then
        set_scale(3, nil, false)
        return
    end

    -- Get the desktop resolution
    local w, h = love.window.getDesktopDimensions(flags.display)
    local desktopResolution = {width = w, height = h}

    -- Find the largest scale that will fit within the desktop resolution
    local scale = 1
    while BASE_SCREEN_W * (scale + 1) <= desktopResolution.width and
          BASE_SCREEN_H * (scale + 1) <= desktopResolution.height do
        scale = scale + 1
    end

    set_scale(scale, desktopResolution, true)
end

function set_scale(scale, resolution, fullscreen)
    -- If no resolution was given
    if not resolution then
        resolution = {width = BASE_SCREEN_W * scale,
                      height = BASE_SCREEN_H * scale}
    end

    local w, h, flags = love.window.getMode()

    -- If the given resolution is different than the current mode
    if resolution.width ~= w or resolution.height ~= h or
       fullscreen ~= flags.fullscreen then

        newFlags = {fullscreentype = 'desktop'}
        if fullscreen then
            newFlags.fullscreen = true
        else
            newFlags.fullscreen = false
        end

        -- If an invalid scale was given, or setMode fails
        if scale < 1 or
           not love.window.setMode(resolution.width, resolution.height,
                                   newFlags) then
            print('error: could not set graphics mode to ' ..
                  resolution.width .. 'x' .. resolution.height)
            return
        end
    end

    SCALE_X = scale
    SCALE_Y = scale

    -- Find the position at which the game screen should be drawn, in order
    -- to produce a letterbox effect if the actual screen is wider or
    -- taller than the game screen
    SCREEN_X = (resolution.width / 2) - ((BASE_SCREEN_W * SCALE_X) / 2)
    SCREEN_Y = (resolution.height / 2) - ((BASE_SCREEN_H * SCALE_Y) / 2)

    -- Load the font at the correct scale
    local img = love.graphics.newImage('res/font/cga.png')
    local glyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÖ 0123456789:.,\'"!?%/'
    font = love.graphics.newImageFont(img, glyphs)
    love.graphics.setFont(font)
end

function upscale_x(x)
    return x * TILE_W * SCALE_X
end

function upscale_y(y)
    return y * TILE_H * SCALE_Y
end
