require('util.graphics')

MenuItem = class('MenuItem')

function MenuItem:init(name, value, options)
    self.name = name or ''
    self.value = value
    self.options = options

    self.optionIndex = 1
    self.isVisible = true
end

function MenuItem:draw(x, y, highlight, flashState)
    local color
    if highlight and flashState then
        color = MAGENTA
    end

    local namePart = self.name
    local valuePart = self:get_value()
    if valuePart then
        if namePart ~= '' then
            namePart = namePart .. ': '
        end

        if self.options then
            valuePart = self:get_left_arrow() ..
                        valuePart ..
                        self:get_right_arrow()
        end
    end

    if valuePart == nil then valuePart = '' end

    cga_print(namePart .. valuePart, x, y,
              {center = true, color = color, bg = false}) 

    -- Draw the name part
    --local valueMask = ''
    --if valuePart then
    --    valueMask = string.rep(' ', string.len(valuePart))
    --end
    --cga_print(namePart .. valueMask, x, y,
    --          {center = true, color = color, bg = false}) 

    --if valuePart then
    --    -- Draw the value part
    --    local nameMask = string.rep(' ', string.len(namePart))
    --    cga_print(nameMask .. valuePart, x, y,
    --              {center = true, color = color, bg = false})
    --end
end

function MenuItem:hide()
    self.isVisible = false
end

function MenuItem:select_option(index)
    self.optionIndex = index
end

function MenuItem:show()
    self.isVisible = true
end

function MenuItem:select_next_option(index)
    if self.options then
        if self.optionIndex < #self.options then
            self.optionIndex = self.optionIndex + 1
        end
    end
end

function MenuItem:select_previous_option(index)
    if self.options then
        if self.optionIndex > 1 then
            self.optionIndex = self.optionIndex - 1
        end
    end
end

function MenuItem:get_left_arrow()
    if self.options then
        if self.optionIndex > 1 and #self.options > 1 then
            return '◄ '
        end
    end

    return ''
end

function MenuItem:get_right_arrow()
    if self.options then
        if self.optionIndex < #self.options then
            return ' ►'
        end
    end

    return ''
end

function MenuItem:get_value()
    if self.value then
        return self.value
    elseif self.options then
        return self.options[self.optionIndex]
    end
end
