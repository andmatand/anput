function cga_print(text, x, y, options)
    -- Set default options
    options = options or {}

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
            xPos = x - (font:getWidth(line) / 2)
        end

        -- Draw a black background behind this line of text
        love.graphics.setColor(BLACK)
        love.graphics.rectangle('fill', xPos, y + upscale_y(i),
                                font:getWidth(line), font:getHeight())

        -- Set the color
        if options.color then
            love.graphics.setColor(options.color)
        else
            love.graphics.setColor(WHITE)
        end

        -- Draw this line of text
        love.graphics.print(line, xPos, y + upscale_y(i))

        -- Keep track of which line number we're on
        i = i + 1
    end
end

function set_scale(scale)
    if scale < 1 then
        return
    end

    -- If the scale changed
    if scale ~= SCALE_X then
        SCALE_X = scale
        SCALE_Y = scale

        love.graphics.setMode(320 * SCALE_X, 200 * SCALE_Y)
    end

    -- Set the screen width and height in # of tiles
    SCREEN_W = (love.graphics.getWidth() / upscale_x(1))
    SCREEN_H = (love.graphics.getHeight() / upscale_y(1))

    -- Load the font at the correct scale
    font = love.graphics.newFont('res/font/cga.ttf', upscale_x(1))
    love.graphics.setFont(font)
end

function draw_progress_bar(barInfo, x, y, w, h)
    bar = {}
    bar.x = x + SCALE_X
    bar.y = y + SCALE_Y
    bar.w = w - (SCALE_X * 2)
    bar.h = h - (SCALE_Y * 2)
    
    -- Draw border
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

function upscale_x(x)
    return x * TILE_W * SCALE_X
end

function upscale_y(y)
    return y * TILE_H * SCALE_Y
end
