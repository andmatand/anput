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
        --love.graphics.setColor(BLACK)
        --love.graphics.rectangle('fill', xPos, y + upscale_y(i),
        --                        SCALE_X * font:getWidth(line),
        --                        font:getHeight() * SCALE_Y)

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
    love.graphics.setLine(1, 'rough')
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

function toggle_fullscreen()
    local w, h, fs = love.graphics.getMode()

    -- If we are already in fullscreen
    if fs then
        set_scale(3, nil, false)
        return
    end

    -- Find the best fullscreen resolution
    local bestResolution = {width = 0, height = 0}
    for _, mode in pairs(love.graphics.getModes()) do
        if mode.width * mode.height >
           bestResolution.width * bestResolution.height then
            bestResolution = mode
        end
    end

    -- Find the largest scale that will fit within the target resolution
    local scale = 1
    while BASE_SCREEN_W * (scale + 1) <= bestResolution.width and
          BASE_SCREEN_H * (scale + 1) <= bestResolution.height do
        scale = scale + 1
    end

    set_scale(scale, bestResolution, true)
end

function set_scale(scale, resolution, fullscreen)
    -- If no resolution was given
    if not resolution then
        resolution = {width = BASE_SCREEN_W * scale,
                      height = BASE_SCREEN_H * scale}
    end

    -- If an invalid scale or an unsupported screen resolution was given
    if scale < 1 or
       not love.graphics.checkMode(resolution.width, resolution.height,
                                   fullscreen) then
        print('error: resolution not supported')
        return
    end

    SCALE_X = scale
    SCALE_Y = scale

    -- Find the position at which the game screen should be drawn, in order
    -- to produce a letterbox effect if the actual screen is wider or
    -- taller than the game screen
    SCREEN_X = (resolution.width / 2) - ((BASE_SCREEN_W * SCALE_X) / 2)
    SCREEN_Y = (resolution.height / 2) - ((BASE_SCREEN_H * SCALE_Y) / 2)

    local w, h, fs = love.graphics.getMode()
    -- If the given scale or resolution is different than the current mode
    if resolution.width ~= w or resolution.height ~= h or
       fullscreen ~= fs then
        love.graphics.setMode(resolution.width, resolution.height, fullscreen)
    end

    -- Load the font at the correct scale
    local img = love.graphics.newImage('res/font/cga.png')
    local glyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789:.,\'"!?'
    font = love.graphics.newImageFont(img, glyphs)
    love.graphics.setFont(font)
end

function upscale_x(x)
    return x * TILE_W * SCALE_X
end

function upscale_y(y)
    return y * TILE_H * SCALE_Y
end
