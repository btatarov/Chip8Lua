local Screen = require('Lib.Screen')

local font_data = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
    0x20, 0x60, 0x20, 0x20, 0x70, -- 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
    0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
    0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
    0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
    0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
    0xF0, 0x80, 0xF0, 0x80, 0x80  -- F
}

local keyboard_mapping = {
    MOAIKeyCode.DIGIT_0,
    MOAIKeyCode.DIGIT_1,
    MOAIKeyCode.DIGIT_2,
    MOAIKeyCode.DIGIT_3,
    MOAIKeyCode.DIGIT_4,
    MOAIKeyCode.DIGIT_5,
    MOAIKeyCode.DIGIT_6,
    MOAIKeyCode.DIGIT_7,
    MOAIKeyCode.DIGIT_8,
    MOAIKeyCode.DIGIT_9,
    MOAIKeyCode.A,
    MOAIKeyCode.B,
    MOAIKeyCode.C,
    MOAIKeyCode.D,
    MOAIKeyCode.E,
    MOAIKeyCode.F,
}

local Chip8 = Flower.class()

Chip8.SCREEN_WIDTH = 64
Chip8.SCREEN_HEIGHT = 32
Chip8.SCALE = 10
Chip8.MEMORY_SIZE = 4096
Chip8.MEMORY_ROM_START = 0x201
Chip8.TIMER_STEP = 17

function Chip8:init(layer)
    self.registers = {
        V = {},
        index = 0,
        pc = Chip8.MEMORY_ROM_START
    }

    self.stack = {}
    self.memory = {}

    self.opcode_lut = {
        ['0'] = self.zero_routines,
        ['1'] = self.jump_to,
        ['2'] = self.call_routine,
        ['3'] = self.skip_if,
        ['4'] = self.skip_if_not,
        ['5'] = self.skip_if_regs_equal,
        ['6'] = self.move_value_to_reg,
        ['7'] = self.add_value_to_reg,
        ['8'] = self.modify_reg_routines,
        ['9'] = self.skip_if_regs_not_equal,
        ['a'] = self.set_index_to_val,
        ['b'] = self.jump_to_plus,
        ['c'] = self.rand_and,
        ['d'] = self.draw_sprite,
        ['e'] = self.keyboard_routines,
        ['f'] = self.f_routines
    }

    -- reset stack, registers
    for i = 0, 15 do
        self.registers.V[i] = 0
    end
    for i = 1, 16 do
        self.stack[i] = 0
    end

    -- reset memory
    for i = 1, Chip8.MEMORY_SIZE do
        self.memory[i] = 0x00
    end

    -- load font
    for i = 1, #font_data do
        self.memory[i] = font_data[i]
    end

    self.screen = Screen(layer)

    -- timers
    self.delay_timer_value = 0
    self.delay_timer = MOAITimer.new()
    self.delay_timer:setMode(MOAITimer.LOOP)
    self.delay_timer:setSpan(Chip8.TIMER_STEP / 1000)
    self.delay_timer:setListener(MOAITimer.EVENT_TIMER_LOOP, function()
        self.delay_timer_value = self.delay_timer_value - 1
        if self.delay_timer_value < 1 then
            self.delay_timer:stop()
            self.delay_timer_value = 0
        end
    end)
end

function Chip8:update()
    self:execute_instruction()
    self.screen:update()
end

function Chip8:loadRom(file_name)
    local file_name = './Roms/' .. file_name

    local f = assert(io.open(file_name, "rb"))
    local data = f:read("*all")
    assert(f:close())

    for i = 1, string.len(data) do
        self.memory[Chip8.MEMORY_ROM_START + (i - 1)] = string.byte(data, i)
    end
end

function Chip8:dumpRegisters()
    for i = 0, 15 do
        print(string.format('V%d: %02X', i, self.registers.V[i]))
    end
end

function Chip8:dumpMemory(start_byte, end_byte)
    local start_byte = start_byte or 1
    local end_byte = end_byte or Chip8.MEMORY_SIZE
    local delim = 16

    local has_printed = false
    local counter = 0
    local memory_str = ''
    for i = start_byte, end_byte do
        counter = counter + 1
        memory_str = memory_str .. string.format('%02X ', self.memory[i])

        if counter % delim == 0 then
            print(memory_str)
            memory_str = ''
            has_printed = true
        end
    end

    if not has_printed then
        print(memory_str)
    end
end

-- 0xxx
function Chip8:zero_routines(first_byte, rest_bytes)
    if rest_bytes == 0xE0 then -- cls
        self.screen:reset()
    elseif rest_bytes == 0xEE then -- ret
        self.registers.pc = (self.stack[#self.stack])
        table.remove(self.stack)
    else
        assert(false, string.format('unknown 0x %x', rest_bytes))
    end
end

-- 1xxx
function Chip8:jump_to(first_byte, rest_bytes)
    local pointer = first_byte * 0x100 + rest_bytes
    self.registers.pc = pointer + 1 - 2 -- pc + 2 after that
end

-- 2xxx
function Chip8:call_routine(first_byte, rest_bytes)
    table.insert(self.stack, self.registers.pc)
    self:jump_to(first_byte, rest_bytes)
end

-- 3xxx
function Chip8:skip_if(param, value)
    if self.registers.V[param] == value then
        self.registers.pc = self.registers.pc + 2
    end
end

-- 4xxx
function Chip8:skip_if_not(param, value)
    if self.registers.V[param] ~= value then
        self.registers.pc = self.registers.pc + 2
    end
end

-- 5xxx
function Chip8:skip_if_regs_equal(first_byte, rest_bytes)
    local x = first_byte
    local y = bit.rshift(bit.band(rest_bytes, 0xF0), 4)
    if self.registers.V[x] == self.registers.V[y] then
        self.registers.pc = self.registers.pc + 2
    end
end

-- 6xxx
function Chip8:move_value_to_reg(param, value)
    self.registers.V[param] = value
end

-- 7xxx
function Chip8:add_value_to_reg(param, value)
    local sum = self.registers.V[param] + value
    if sum > 255 then sum = sum - 256 end
    self.registers.V[param] = sum
end

-- 8xxx
function Chip8:modify_reg_routines(first_byte, rest_bytes)
    local x = first_byte
    local y = bit.rshift(bit.band(rest_bytes, 0xF0), 4)
    local modifier = bit.band(rest_bytes, 0xF)

    if modifier == 0 then
        self.registers.V[x] = self.registers.V[y]
    elseif modifier == 0x1 then
        self.registers.V[x] = bit.bor(self.registers.V[x], self.registers.V[y])
    elseif modifier == 0x2 then
        self.registers.V[x] = bit.band(self.registers.V[x], self.registers.V[y])
    elseif modifier == 0x3 then
        self.registers.V[x] = bit.bxor(self.registers.V[x], self.registers.V[y])
    elseif modifier == 0x4 then
        local sum = self.registers.V[x] + self.registers.V[y]
        if sum > 255 then
            self.registers.V[0xF] = 1
            sum = sum - 256
        else
            self.registers.V[0xF] = 0
        end
        self.registers.V[x] = sum
    elseif modifier == 0x5 then
        local subs = self.registers.V[x] - self.registers.V[y]
        if subs >= 0 then
            self.registers.V[0xF] = 1
        else
            subs = 256 + subs
            self.registers.V[0xF] = 0
        end
        self.registers.V[x] = subs
    elseif modifier == 0x6 then
        self.registers.V[x] = bit.rshift(self.registers.V[x], 1)
        self.registers.V[0xF] = bit.band(self.registers.V[x], 0x1)
    elseif modifier == 0x7 then
        local subs = self.registers.V[y] - self.registers.V[x]
        if subs >= 0 then
            self.registers.V[0xF] = 1
        else
            subs = 256 + subs
            self.registers.V[0xF] = 0
        end
        self.registers.V[x] = subs
    elseif modifier == 0xE then
        self.registers.V[x] = bit.lshift(self.registers.V[x], 1)
        self.registers.V[0xF] = bit.rshift(bit.band(self.registers.V[x], 0x80), 8)
    else
        assert(false, string.format('unknown 8x %x', rest_bytes))
    end
end

-- 9xxx
function Chip8:skip_if_regs_not_equal(first_byte, rest_bytes)
    local x = first_byte
    local y = bit.rshift(bit.band(rest_bytes, 0xF0), 4)
    if self.registers.V[x] ~= self.registers.V[y] then
        self.registers.pc = self.registers.pc + 2
    end
end

-- Axxx
function Chip8:set_index_to_val(first_byte, rest_bytes)
    local val = first_byte * 0x100 + rest_bytes
    self.registers.index = val
end

-- Bxxx
function Chip8:jump_to_plus(first_byte, rest_bytes)
    local pointer = first_byte * 0x100 + rest_bytes + self.registers.index
    self.registers.pc = pointer + 1 - 2 -- pc + 2 after that
end

-- Cxxx
function Chip8:rand_and(param, value)
    self.registers.V[param] = bit.band(math.random(0, 255), value)
end

-- Dxxx
function Chip8:draw_sprite(first_byte, rest_bytes)
    local x = self.registers.V[first_byte]
    local y = self.registers.V[bit.rshift(bit.band(rest_bytes, 0xF0), 4)]
    local n = bit.band(rest_bytes, 0xF)
    self.registers.V[0xF] = 0

    local sprite_data = {}
    for i = 1, n do
        sprite_data[i] = self.memory[self.registers.index + i]
    end

    for i = 1, n do
        for j = 1, 8 do
            local pos_x = x + 1 + (j - 1)
            local pos_y = y + 1 + (i - 1)
            pos_x = (pos_x - 1) % Chip8.SCREEN_WIDTH + 1
            pos_y = (pos_y - 1) % Chip8.SCREEN_HEIGHT + 1

            local color = (bit.band(sprite_data[i], bit.lshift(1, (8 - j))) ~= 0) and 1 or 0
            local cur_color = self.screen:getPixel(pos_x, pos_y)

            if color == 1 and cur_color == 1 then
                color = 0
                self.registers.V[0xF] = bit.bor(self.registers.V[0xF], 1)
            elseif color == 0 and cur_color == 1 then
                color = 1
            end

            self.screen:setPixel(pos_x, pos_y, color)
        end
    end
end

-- Exxx
function Chip8:keyboard_routines(param, rest_bytes)
    local key = keyboard_mapping[self.registers.V[param] + 1]

    if rest_bytes == 0x9E then -- skip if pressed
        if Flower.InputMgr:keyIsDown(key) then
            self.registers.pc = self.registers.pc + 2
        end
    elseif rest_bytes == 0xA1 then -- skip if not pressed
        if not Flower.InputMgr:keyIsDown(key) then
            self.registers.pc = self.registers.pc + 2
        end
    else
        assert(false, string.format('unknown ex %x', rest_bytes))
    end
end

-- Fxxx
function Chip8:f_routines(param, rest_bytes)
    if rest_bytes == 0x07 then
        self.registers.V[param] = self.delay_timer_value
    elseif rest_bytes == 0x0A then
        -- TODO: Wait for a key press, store the value of the key in Vx.
        assert(false, 'fx0A is not implemented - wait for keypress')
    elseif rest_bytes == 0x15 then
        self.delay_timer_value = self.registers.V[param]
        self:start_delay_timer()
    elseif rest_bytes == 0x18 then
        -- TODO: Set sound timer = Vx.
        -- print('sound is not implemented')
    elseif rest_bytes == 0x1E then
        self.registers.index = self.registers.index + self.registers.V[param]
    elseif rest_bytes == 0x29 then
        self.registers.index = self.registers.V[param] * 5
    elseif rest_bytes == 0x33 then
        local param = string.format('%03d', self.registers.V[param])
        self.memory[self.registers.index + 1] = tonumber(string.sub(param, 1, 1))
        self.memory[self.registers.index + 2] = tonumber(string.sub(param, 2, 2))
        self.memory[self.registers.index + 3] = tonumber(string.sub(param, 3, 3))
    elseif rest_bytes == 0x55 then
        for i = 0, param do
            self.memory[self.registers.index + 1 + i] = self.registers.V[i]
        end
    elseif rest_bytes == 0x65 then
        for i = 0, param do
            self.registers.V[i] = self.memory[self.registers.index + 1 + i]
        end
    else
        assert(false, string.format('unknown fx %x', rest_bytes))
    end
end

function Chip8:execute_instruction()
    local op_code = { self.memory[self.registers.pc], self.memory[self.registers.pc + 1] }

    local first_byte = bit.rshift(bit.band(op_code[1], 0xF0), 4)
    local second_byte = bit.band(op_code[1], 0xF)

    local opcode_func = self.opcode_lut[ string.format('%x', first_byte) ]
    -- print(string.format('executing %x with params: %x', first_byte, second_byte), string.format('%02x', op_code[2]))
    opcode_func(self, second_byte, op_code[2])

    self.registers.pc = self.registers.pc + 2
end

function Chip8:start_delay_timer()
    self.delay_timer:stop()
    self.delay_timer:start()
end

return Chip8
