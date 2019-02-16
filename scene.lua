module(..., package.seeall)

function onCreate(e)
    local layer = Flower.Layer()
    layer:setTouchEnabled(false)
    scene:addChild(layer)

    local screen_rects = {}
    for i = 1, Chip8.screenWidth do
        for j = 1, Chip8.screenHeight do
            local color = {1, 1, 1, 1}
            local rect = Flower.Rect(CONFIG.scale, CONFIG.scale, color)
            rect:setPos((i - 1) * CONFIG.scale, (j - 1) * CONFIG.scale)
            rect:setLayer(layer)
            rect:setVisible(false)

            table.insert(screen_rects, rect)
        end
    end
end

function onStart(e)
end

function onClose(e)
end
