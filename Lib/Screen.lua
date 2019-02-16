local Screen = Flower.class()

function Screen:init(layer)
    self.screen_data = {}

    self.screen_rects = {}
    for i = 1, Chip8.SCREEN_HEIGHT do
        for j = 1, Chip8.SCREEN_WIDTH do
            local color = {1, 1, 1, 1}
            local rect = Flower.Rect(Chip8.SCALE, Chip8.SCALE, color)
            rect:setPos((j - 1) * Chip8.SCALE, (i - 1) * Chip8.SCALE)
            rect:setLayer(layer)
            rect:setVisible(false)

            table.insert(self.screen_rects, rect)
        end
    end

    self:reset()

    -- for i = 1, Chip8.SCREEN_WIDTH * Chip8.SCREEN_HEIGHT do
    --     if i % 3 == 0 then
    --         local y = math.ceil(i / Chip8.SCREEN_HEIGHT)
    --         local x = (i - (y - 1) * Chip8.SCREEN_HEIGHT)
    --         self:setPixel(x, y, 1)
    --     end
    -- end
end

function Screen:dump()
    local line_str = ''
    for i = 1, Chip8.SCREEN_WIDTH * Chip8.SCREEN_HEIGHT do
        line_str = string.format('%s %s', line_str, self.screen_data[i])

        if i % Chip8.SCREEN_WIDTH == 0 then
            print(line_str)
            line_str = ''
        end
    end
end

function Screen:reset()
    for i = 1, Chip8.SCREEN_WIDTH * Chip8.SCREEN_HEIGHT do
        self.screen_data[i] = 0
    end
end

function Screen:update()
    for i = 1, Chip8.SCREEN_WIDTH * Chip8.SCREEN_HEIGHT do
        local val = (self.screen_data[i] == 1) and true or false
        self.screen_rects[i]:setVisible(val)
    end
end

function Screen:getPixel(x, y)
    return self.screen_data[(y - 1) * Chip8.SCREEN_WIDTH + x]
end

function Screen:setPixel(x, y, color)
    self.screen_data[(y - 1) * Chip8.SCREEN_WIDTH + x] = color
end

return Screen
