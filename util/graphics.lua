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
        love.graphics.printf(line, xPos, y + upscale_y(i),
                             font:getWidth(line) + 1, 'center')

        -- Keep track of which line number we're on
        i = i + 1
    end
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
