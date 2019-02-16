CONFIG = require('config')

Chip8 = require('Lib.Chip8')
Flower = require('Lib.Flower')

Flower.openWindow('Chip8 Emulator', Chip8.screenWidth * CONFIG.scale, Chip8.screenHeight * CONFIG.scale)
Flower.openScene('scene')
