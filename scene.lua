module(..., package.seeall)

function onCreate(e)
    local layer = Flower.Layer()
    layer:setTouchEnabled(false)
    scene:addChild(layer)

    local chip8 = Chip8(layer)
    chip8:loadRom('INVADERS')

    local MainLoop = MOAIThread.new()
    MainLoop:run(function()
        while(true) do
            for counter = 1, math.floor(1000 / 60) do -- 1000 instructions per second
                chip8:update()
            end
            coroutine:yield()
            -- break
        end
    end)
end

function onStart(e)
end

function onClose(e)
end
