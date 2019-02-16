MOAISim.setStep(1 / 60)
MOAISim.clearLoopFlags()
MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED)
MOAISim.setBoostThreshold(0)
MOAISim.setCpuBudget(4)

Flower = require('Lib.Flower')
Chip8 = require('Lib.Chip8')

Flower.openWindow('Chip8 Emulator', Chip8.SCREEN_WIDTH * Chip8.SCALE, Chip8.SCREEN_HEIGHT * Chip8.SCALE)
Flower.openScene('scene')
