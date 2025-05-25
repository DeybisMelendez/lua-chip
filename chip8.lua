local chip8 = {
    memory = {},
    display = {},
    registers = { 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0 },
    stack = {},
    delayTimer = 0,
    soundTimer = 0,
    pc = 0x200, -- Program counter starts at 0x200
    sp = 0,     -- Stack pointer
    I = 1,      -- Index register
}
local bit = require 'bit'

function chip8:onLoad()
    local file = io.open(GamePath, "rb")
    if not file then
        error("Could not open file: " .. GamePath)
    end

    local data = file:read("*a")
    file:close()
    -- Cargar el juego en memoria empezando desde 0x200
    for i = 0, #data - 1 do
        local byte = string.byte(data, i + 1)
        self.memory[0x200 + i] = byte
    end
    self:tick()
end

function chip8:update(dt)
    -- Actualizar temporizadores
    if self.delayTimer > 0 then
        self.delayTimer = self.delayTimer - dt
    end
    if self.soundTimer > 0 then
        self.soundTimer = self.soundTimer - dt
        if self.soundTimer == 0 then
            -- Reproducir sonido aquí
        end
    end

    -- Simular un ciclo de CPU
    --self:tick()
end

function chip8:draw()
    -- Dibujar la pantalla
    for y = 0, 31 do
        for x = 0, 63 do
            local pixel = self.display[y * 64 + x]
            if pixel == 1 then
                love.graphics.setColor(1, 1, 1) -- Blanco
            else
                love.graphics.setColor(0, 0, 0) --
            end
            love.graphics.points(x, y)
        end
    end
end

function chip8:keypressed(key)
    if key == "space" then
        -- Simular un ciclo de CPU al presionar espacio
        self:tick()
    end
end

function chip8:tick()
    -- Simular un ciclo de CPU
    local opcode = bit.bor(
        bit.lshift(self.memory[self.pc], 8),
        self.memory[self.pc + 1]
    )
    self.pc = self.pc + 2 -- Incrementar el contador de programa
    self:executeOpcode(opcode)
    local firstNibble = bit.rshift(opcode, 12)
    print(string.format("Opcode: 0x%04X, FirstNiblle: 0x%02X", opcode, firstNibble))
end

function chip8:executeOpcode(opcode)
    if opcode == 0x00E0 then -- CLS
        --  Clear the display.
        for i = 1, #self.display do
            self.display[i] = 0
        end
    elseif opcode == 0x00EE then -- RET
        --  Return from a subroutine.
        if self.sp > 0 then
            self.sp = self.sp - 1
            self.pc = self.stack[self.sp]
        end
    elseif opcode >= 0x1000 and opcode < 0x2000 then -- 1NNN
        --  Jump to location nnn.
        local address = bit.band(opcode, 0x0FFF)
        self.stack[self.sp] = self.pc
        self.sp = self.sp + 1
        self.pc = address
    elseif opcode >= 0x2000 and opcode < 0x3000 then -- 2NNN
        -- Call subroutine at nnn.
        local address = bit.band(opcode, 0x0FFF)
        self.stack[self.sp] = self.pc
        self.sp = self.sp + 1
        self.pc = address
    elseif opcode >= 0x3000 and opcode < 0x4000 then -- 3XNN
        -- Skip next instruction if Vx == NN
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local nn = bit.band(opcode, 0x00FF)
        if self.registers[x] == nn then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0x4000 and opcode < 0x5000 then -- 4XNN
        -- Skip next instruction if Vx != NN
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local nn = bit.band(opcode, 0x00FF)
        if self.registers[x] ~= nn then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0x5000 and opcode < 0x6000 then -- 5XY0
        -- Skip next instruction if Vx == Vy
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local y = bit.band(bit.rshift(opcode, 4), 0x0F)
        if self.registers[x] == self.registers[y] then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0x6000 and opcode < 0x7000 then -- 6XNN
        -- Set Vx = KK
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local kk = bit.band(opcode, 0x00FF)
        self.registers[x] = kk
    elseif opcode >= 0x7000 and opcode < 0x8000 then -- 7XNN
        -- Set Vx = Vx + KK
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local kk = bit.band(opcode, 0x00FF)
        self.registers[x] = bit.band(self.registers[x] + kk, 0xFF)
    elseif opcode >= 0x8000 and opcode < 0x9000 then -- 8XY0
        if bit.band(opcode, 0x000F) == 0 then
            -- Set Vx = Vy
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = self.registers[y]
        elseif bit.band(opcode, 0x000F) == 1 then
            -- Set Vx = Vx OR Vy
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = bit.bor(self.registers[x], self.registers[y])
        elseif bit.band(opcode, 0x000F) == 2 then
            -- Set Vx = Vx AND Vy
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = bit.band(self.registers[x], self.registers[y])
        elseif bit.band(opcode, 0x000F) == 3 then
            -- Set Vx = Vx XOR Vy
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = bit.bxor(self.registers[x], self.registers[y])
        elseif bit.band(opcode, 0x000F) == 4 then
            -- Set Vx = Vx + Vy, set VF = carry
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            local sum = self.registers[x] + self.registers[y]
            self.registers[0xF] = sum > 255 and 1 or 0
            self.registers[x] = bit.band(sum, 0xFF)
        elseif bit.band(opcode, 0x000F) == 5 then
            -- Set Vx = Vx - Vy, set VF = NOT borrow
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            self.registers[0xF] = self.registers[x] > self.registers[y] and 1 or 0
            self.registers[x] = bit.band(self.registers[x] - self.registers[y], 0xFF)
        elseif bit.band(opcode, 0x000F) == 6 then
            -- Shift Vx right by 1, set VF = least significant bit of Vx before shift
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.registers[0xF] = bit.band(self.registers[x], 0x01)
            self.registers[x] = bit.rshift(self.registers[x], 1)
        elseif bit.band(opcode, 0x000F) == 7 then
            -- Set Vx = Vy - Vx, set VF = NOT borrow
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            local y = bit.band(bit.rshift(opcode, 4), 0x0F)
            self.registers[0xF] = self.registers[y] > self.registers[x] and 1 or 0
            self.registers[x] = bit.band(self.registers[y] - self.registers[x], 0xFF)
        elseif bit.band(opcode, 0x000F) == 0xE then
            -- Shift Vx left by 1, set VF = most significant bit of Vx before shift
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.registers[0xF] = bit.rshift(self.registers[x], 7)
            self.registers[x] = bit.lshift(self.registers[x], 1)
        else
            print("Unknown opcode: " .. string.format("0x%04X", opcode))
        end
    elseif opcode >= 0x9000 and opcode < 0xA000 then -- 9XY0
        -- Skip next instruction if Vx != Vy
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local y = bit.band(bit.rshift(opcode, 4), 0x0F)
        if self.registers[x] ~= self.registers[y] then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0xA000 and opcode < 0xB000 then -- ANNN
        -- Set I = nnn
        local nnn = bit.band(opcode, 0x0FFF)
        self.I = nnn
    elseif opcode >= 0xB000 and opcode < 0xC000 then -- BNNN
        -- Jump to location nnn + V0
        local nnn = bit.band(opcode, 0x0FFF)
        self.pc = nnn + self.registers[0]
    elseif opcode >= 0xC000 and opcode < 0xD000 then -- CXNN
        -- Set Vx = random byte AND NN
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local nn = bit.band(opcode, 0x00FF)
        self.registers[x] = bit.band(math.random(0, 255), nn)
    elseif opcode >= 0xD000 and opcode < 0xE000 then -- DXYN
        -- Draw sprite at coordinate (Vx, Vy) with N bytes of sprite data
        local x = bit.band(bit.rshift(opcode, 8), 0x0F)
        local y = bit.band(bit.rshift(opcode, 4), 0x0F)
        local n = bit.band(opcode, 0x000F)
        self.registers[0xF] = 0 -- Clear VF before drawing
        for i = 0, n - 1 do
            local byte = self.memory[self.I + i]
            for j = 0, 7 do
                local pixel = bit.band(byte, bit.lshift(1, 7 - j))
                if pixel ~= 0 then
                    local px = (self.registers[x] + j) % 64
                    local py = (self.registers[y] + i) % 32
                    if self.display[py * 64 + px] == 1 then
                        self.registers[0xF] = 1 -- Collision detected
                    end
                    self.display[py * 64 + px] = bit.bxor(self.display[py * 64 + px], pixel)
                end
            end
        end
    elseif opcode >= 0xE000 and opcode < 0xF000 then -- EXXX
        if bit.band(opcode, 0x00FF) == 0x009E then
            -- Skip next instruction if key with value of Vx is pressed
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            if self.keypad[self.registers[x]] then
                self.pc = self.pc + 2
            end
        elseif bit.band(opcode, 0x00FF) == 0x00A1 then
            -- Skip next instruction if key with value of Vx is not pressed
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            if not self.keypad[self.registers[x]] then
                self.pc = self.pc + 2
            end
        else
            print("Unknown opcode: " .. string.format("0x%04X", opcode))
        end
    elseif opcode >= 0xF000 and opcode < 0x10000 then -- FXNN
        if bit.band(opcode, 0x00FF) == 0x0007 then
            -- Set Vx = delay timer value
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.registers[x] = self.delayTimer
        elseif bit.band(opcode, 0x00FF) == 0x000A then
            -- Wait for a key press, store the value of the key in Vx
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            -- Implement key wait logic here
        elseif bit.band(opcode, 0x00FF) == 0x0015 then
            -- Set delay timer = Vx
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.delayTimer = self.registers[x]
        elseif bit.band(opcode, 0x00FF) == 0x0018 then
            -- Set sound timer = Vx
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.soundTimer = self.registers[x]
        elseif bit.band(opcode, 0x00FF) == 0x001E then
            -- Set I = I + Vx
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.I = self.I + self.registers[x]
        elseif bit.band(opcode, 0x00FF) == 0x0029 then
            -- Set I = location of sprite for digit Vx
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            self.I = self.registers[x] * 5 -- Assuming each sprite is 5 bytes
        elseif bit.band(opcode, 0x00FF) == 0x0033 then
            -- Store BCD representation of Vx in memory locations I, I+1, and I+2
            local x                 = bit.band(bit.rshift(opcode, 8), 0x0F)
            local value             = self.registers[x]
            self.memory[self.I]     = math.floor(value / 100)
            self.memory[self.I + 1] = math.floor((value % 100))
            self.memory[self.I + 2] = value % 10
        elseif bit.band(opcode, 0x00FF) == 0x0055 then
            -- Store registers V0 to Vx in memory starting at location I
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            for i = 0, x do
                self.memory[self.I + i] = self.registers[i]
            end
        elseif bit.band(opcode, 0x00FF) == 0x0065 then
            -- Read registers V0 to Vx from memory starting at location I
            local x = bit.band(bit.rshift(opcode, 8), 0x0F)
            for i = 0, x do
                self.registers[i] = self.memory[self.I + i]
            end
        else
            print("Unknown opcode: " .. string.format("0x%04X", opcode))
        end
    else
        print("Unknown opcode: " .. string.format("0x%04X", opcode))
    end
end

function chip8:clearScreen()

end

function chip8:popStack()

end

return chip8
