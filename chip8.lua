local chip8 = {
    memory = {},
    display = {},
    keypad = {},
    registers = {},
    tickRate = 1 / 60,
    stack = {},
    mode = 0, -- Modo de emulación chip8 por defecto
    debug = false,
    modes = {
        chip8 = 0,
        superChip = 1,
    },
    quirks = {
        -- Chip 8 quirks
        vfReset = false,
        memory = false,
        dispWait = true,
        clipping = true,
        shifting = true,
        jumping = false
    },
    keymap = {
        ["1"] = 0x1,
        ["2"] = 0x2,
        ["3"] = 0x3,
        ["4"] = 0xC,
        ["q"] = 0x4,
        ["w"] = 0x5,
        ["e"] = 0x6,
        ["r"] = 0xD,
        ["a"] = 0x7,
        ["s"] = 0x8,
        ["d"] = 0x9,
        ["f"] = 0xE,
        ["z"] = 0xA,
        ["x"] = 0x0,
        ["c"] = 0xB,
        ["v"] = 0xF,
    },
    colors = {
        { bg = { 0, 0, 0 },     color = { 1, 1, 1 } },
        { bg = { 0, 0, 0 },     color = { 0, 1, 0 } },
        { bg = { 0, 0, 0 },     color = { 0, 1, 1 } },
        { bg = { 0, 0, 0 },     color = { 1, 1, 0 } },
        { bg = { 0.5, 0.2, 1 }, color = { 1, 1, 1 } },
        { bg = { 1, 1, 1 },     color = { 0, 0, 0 } },
        { bg = { 0.1, 0.1, 1 }, color = { 0.9, 0.9, 1 } },
        { bg = { 0, 1, 0 },     color = { 0, 0.2, 0 } },
    },
    currentColor = 1
}
function chip8:onLoad()
    self:reset()
    self:loadGame()
end

function chip8:reset()
    self.mode = self.modes.chip8
    -- Resetear memoria
    for i = 0, 0xFFF do
        self.memory[i] = 0
    end
    -- Resetear display
    for i = 0, 64 * 32 - 1 do
        self.display[i] = 0
    end
    -- Resetear registros
    for i = 0, 15 do
        self.registers[i] = 0
        self.keypad[i] = 0
    end
    -- Resetear stack
    self.stack = {}
    self.sp = 0
    self.pc = 0x200
    self.I = 0
    self.delayTimer = 0
    self.soundTimer = 0
    self.timerAccumulator = 0
    self.waitingForKey = false
    self.waitingRegister = nil
    self.beepSource = self:createBeepSound()
    for i = 0, 15 do self.keypad[i] = 0 end
    local fontset = {
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

    for i = 0, #fontset - 1 do
        self.memory[0x050 + i] = fontset[i + 1]
    end
    -- Fontset extendido (SCHIP/SuperCHIP) - caracteres 0-F, 8x10
    local fontset_extended = {
        -- 0
        0xF0, 0x90, 0x90, 0x90, 0xF0,
        0x90, 0x90, 0x90, 0x90, 0xF0,
        -- 1
        0x20, 0x60, 0x20, 0x20, 0x20,
        0x20, 0x20, 0x20, 0x20, 0x70,
        -- 2
        0xF0, 0x10, 0x10, 0x10, 0xF0,
        0x80, 0x80, 0x80, 0x80, 0xF0,
        -- 3
        0xF0, 0x10, 0x10, 0x10, 0xF0,
        0x10, 0x10, 0x10, 0x10, 0xF0,
        -- 4
        0x90, 0x90, 0x90, 0x90, 0xF0,
        0x10, 0x10, 0x10, 0x10, 0x10,
        -- 5
        0xF0, 0x80, 0x80, 0x80, 0xF0,
        0x10, 0x10, 0x10, 0x10, 0xF0,
        -- 6
        0xF0, 0x80, 0x80, 0x80, 0xF0,
        0x90, 0x90, 0x90, 0x90, 0xF0,
        -- 7
        0xF0, 0x10, 0x10, 0x10, 0x10,
        0x10, 0x10, 0x10, 0x10, 0x10,
        -- 8
        0xF0, 0x90, 0x90, 0x90, 0xF0,
        0x90, 0x90, 0x90, 0x90, 0xF0,
        -- 9
        0xF0, 0x90, 0x90, 0x90, 0xF0,
        0x10, 0x10, 0x10, 0x10, 0xF0,
        -- A
        0xF0, 0x90, 0x90, 0x90, 0xF0,
        0x90, 0x90, 0x90, 0x90, 0x90,
        -- B
        0xE0, 0x90, 0x90, 0x90, 0xE0,
        0x90, 0x90, 0x90, 0x90, 0xE0,
        -- C
        0xF0, 0x80, 0x80, 0x80, 0x80,
        0x80, 0x80, 0x80, 0x80, 0xF0,
        -- D
        0xE0, 0x90, 0x90, 0x90, 0x90,
        0x90, 0x90, 0x90, 0x90, 0xE0,
        -- E
        0xF0, 0x80, 0x80, 0x80, 0xF0,
        0x80, 0x80, 0x80, 0x80, 0xF0,
        -- F
        0xF0, 0x80, 0x80, 0x80, 0xF0,
        0x80, 0x80, 0x80, 0x80, 0x80,
    }
    for i = 0, #fontset_extended - 1 do
        self.memory[0x100 + i] = fontset_extended[i + 1]
    end
end

function chip8:loadGame()
    local file = io.open(GamePath, "rb")
    if not file then
        error("Could not open file: " .. GamePath)
    end

    local data = file:read("*a")
    file:close()
    -- Cargar el juego en memoria empezando desde 0x200
    for i = 1, #data do
        local byte = string.byte(data, i)
        self.memory[0x1FF + i] = byte
    end
end

function chip8:createBeepSound()
    local sampleRate = 44100
    local duration = 0.1  -- duración del beep en segundos
    local frequency = 440 -- frecuencia en Hz (La4)
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = math.sin(2 * math.pi * frequency * t)
        soundData:setSample(i, value)
    end

    return love.audio.newSource(soundData, "static")
end

function chip8:update(dt)
    -- Acumular tiempo para manejar temporizadores a 60 Hz
    self.timerAccumulator = (self.timerAccumulator or 0) + dt

    while self.timerAccumulator >= self.tickRate do
        if self.soundTimer > 0 then
            self.soundTimer = self.soundTimer - 1
            if not self.beepSource:isPlaying() then
                self.beepSource:play()
            end
        end
        self.timerAccumulator = self.timerAccumulator - self.tickRate
    end
    -- Actualizar temporizadores
    if self.delayTimer > 0 then
        self.delayTimer = self.delayTimer - 1
    end
    if self.waitingForKey then
        return
    end
    -- Ejecutar ciclos de CPU (puedes ajustar la cantidad para velocidad adecuada)
    if self.mode == self.modes.chip8 then
        -- Chip-8 tiene un ciclo de CPU más lento, por lo que ejecutamos menos ciclos
        for _ = 1, 8 do
            self:tick()
        end
    elseif self.mode == self.modes.superChip then
        -- SuperChip puede ejecutar más ciclos por tick
        for _ = 1, 20 do
            self:tick()
        end
    end
end

function chip8:draw()
    local color = self.colors[self.currentColor]

    love.graphics.setBackgroundColor(color.bg)

    love.graphics.setColor(color.color)

    if self.mode == self.modes.chip8 then
        for y = 0, 31 do
            for x = 0, 63 do
                if self.display[y * 64 + x] == 1 then
                    love.graphics.rectangle("fill", x * 8, y * 8, 7, 7)
                end
            end
        end
    elseif self.mode == self.modes.superChip then
        for y = 0, 63 do
            for x = 0, 127 do
                if self.display[y * 128 + x] == 1 then
                    love.graphics.rectangle("fill", x * 4, y * 4, 3, 3)
                end
            end
        end
    end
end

function chip8:keypressed(key)
    local chip8Key = self.keymap[key]
    if chip8Key then
        self.keypad[chip8Key] = 1
    end
    if key == "escape" then
        self:setScene("menu")
    end
    if key == "tab" then
        chip8.currentColor = chip8.currentColor % #chip8.colors + 1
    end
end

function chip8:keyreleased(key)
    local chip8Key = self.keymap[key]
    if chip8Key then
        self.keypad[chip8Key] = 0
        if self.waitingForKey then
            self.registers[self.waitingRegister] = chip8Key
            self.waitingForKey = false
            self.waitingRegister = nil
        end
    end
end

function chip8:tick()
    if self.waitingForKey then
        for i = 0, 15 do
            if self.keypad[i] == 1 then
                self.registers[self.waitingRegister] = i
                self.waitingForKey = false
                self.waitingRegister = nil
                break
            end
        end
        return -- No ejecutar más instrucciones hasta que se presione una tecla
    end
    -- Simular un ciclo de CPU
    local opcode = Bit.bor(
        Bit.lshift(self.memory[self.pc], 8),
        self.memory[self.pc + 1]
    )
    self.pc = self.pc + 2 -- Incrementar el contador de programa
    self:executeOpcode(opcode)
    if self.debug then
        print(string.format("PC: 0x%04X, Opcode: 0x%04X, ", self.pc, opcode))
        print("Registers: " .. table.concat(self.registers, ", "))
        print("Stack: " .. table.concat(self.stack, ", "))
        print("I: " .. string.format("0x%04X", self.I))
        print("Delay Timer: " .. self.delayTimer)
        print("Sound Timer: " .. self.soundTimer)
        print("--------------------")
    end
end

function chip8:executeOpcode(opcode)
    if opcode > 0x00C0 and opcode < 0x00CF and self.mode == self.modes.superChip then
        -- Scroll display N lines down
        local n = Bit.band(opcode, 0x000F)
        if n > 0 then
            for i = 1, n do
                -- Desplazar la pantalla hacia abajo
                for y = 63, 1, -1 do
                    for x = 0, 63 do
                        self.display[y * 64 + x] = self.display[(y - 1) * 64 + x]
                    end
                end
                -- Limpiar la primera línea
                for x = 0, 63 do
                    self.display[x] = 0
                end
            end
        end
    elseif opcode == 0x00E0 then -- CLS
        --  Clear the display.
        for i = 1, #self.display do
            self.display[i] = 0
        end
    elseif opcode == 0x00EE then -- RET
        --  Return from a subroutine.
        self.sp = self.sp - 1
        self.pc = self.stack[self.sp]
    elseif opcode == 0x00FB and self.mode == self.modes.superChip then
        -- Scroll display right by 4 pixels
        for y = 0, 31 do
            for x = 63, 4, -1 do
                self.display[y * 64 + x] = self.display[y * 64 + (x - 4)]
            end
            for x = 0, 3 do
                self.display[y * 64 + x] = 0
            end
        end
    elseif opcode == 0x00FC and self.mode == self.modes.superChip then
        -- Scroll display left by 4 pixels
        for y = 0, 31 do
            for x = 0, 59 do
                self.display[y * 64 + x] = self.display[y * 64 + (x + 4)]
            end
            for x = 60, 63 do
                self.display[y * 64 + x] = 0
            end
        end
    elseif opcode == 0x00FD and self.mode == self.modes.superChip then
        -- Exit the emulator
        self:setScene("menu")
    elseif opcode == 0x00FF then
        self.mode = self.modes.superChip
        self.quirks.vfReset = true
        self.quirks.memory = true
        self.quirks.dispWait = false
        self.quirks.clipping = false
        self.quirks.shifting = true
        self.quirks.jumping = true
        print("Switched to SuperCHIP mode")
    elseif opcode == 0x00FE then
        self.mode = self.modes.chip8
        self.quirks.vfReset = false
        self.quirks.memory = false
        self.quirks.dispWait = true
        self.quirks.clipping = true
        self.quirks.shifting = true
        self.quirks.jumping = false
        print("Switched to CHIP-8 mode")
    elseif opcode >= 0x1000 and opcode < 0x2000 then -- 1NNN
        --  Jump to location nnn.
        local address = Bit.band(opcode, 0x0FFF)
        self.pc = address
    elseif opcode >= 0x2000 and opcode < 0x3000 then -- 2NNN
        -- Call subroutine at nnn.
        local address = Bit.band(opcode, 0x0FFF)
        self.stack[self.sp] = self.pc
        self.sp = self.sp + 1
        self.pc = address
    elseif opcode >= 0x3000 and opcode < 0x4000 then -- 3XNN
        -- Skip next instruction if Vx == NN
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local nn = Bit.band(opcode, 0x00FF)
        if self.registers[x] == nn then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0x4000 and opcode < 0x5000 then -- 4XNN
        -- Skip next instruction if Vx != NN
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local nn = Bit.band(opcode, 0x00FF)
        if self.registers[x] ~= nn then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0x5000 and opcode < 0x6000 then -- 5XY0
        -- Skip next instruction if Vx == Vy
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
        if self.registers[x] == self.registers[y] then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0x6000 and opcode < 0x7000 then -- 6XNN
        -- Set Vx = KK
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local kk = Bit.band(opcode, 0x00FF)
        self.registers[x] = kk
    elseif opcode >= 0x7000 and opcode < 0x8000 then -- 7XNN
        -- Set Vx = Vx + KK
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local kk = Bit.band(opcode, 0x00FF)
        self.registers[x] = (self.registers[x] + kk) % 256
    elseif opcode >= 0x8000 and opcode < 0x9000 then -- 8XY0
        if Bit.band(opcode, 0x000F) == 0 then
            -- Set Vx = Vy
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = self.registers[y]
        elseif Bit.band(opcode, 0x000F) == 1 then
            -- Set Vx = Vx OR Vy
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = Bit.bor(self.registers[x], self.registers[y])
            if self.quirks.vfReset then
                self.registers[0xF] = 0 -- Reset VF
            end
        elseif Bit.band(opcode, 0x000F) == 2 then
            -- Set Vx = Vx AND Vy
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = Bit.band(self.registers[x], self.registers[y])
            if self.quirks.vfReset then
                self.registers[0xF] = 0 -- Reset VF
            end
        elseif Bit.band(opcode, 0x000F) == 3 then
            -- Set Vx = Vx XOR Vy
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            self.registers[x] = Bit.bxor(self.registers[x], self.registers[y])
            if self.quirks.vfReset then
                self.registers[0xF] = 0 -- Reset VF
            end
        elseif Bit.band(opcode, 0x000F) == 4 then
            -- Set Vx = Vx + Vy, set VF = carry
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            local sum = self.registers[x] + self.registers[y]
            self.registers[x] = Bit.band(sum, 0xFF)
            self.registers[0xF] = sum > 255 and 1 or 0
        elseif Bit.band(opcode, 0x000F) == 5 then
            -- Set Vx = Vx - Vy, set VF = 0 on borrow
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            if self.registers[x] >= self.registers[y] then
                self.registers[x] = Bit.band(self.registers[x] - self.registers[y], 0xFF)
                self.registers[0xF] = 1
            else
                self.registers[x] = Bit.band(self.registers[x] - self.registers[y], 0xFF)
                self.registers[0xF] = 0
            end
        elseif Bit.band(opcode, 0x000F) == 6 then
            -- Set VF = least significant bit of Vx, then Vx = Vx >> 1 or Vx = Vy >> 1
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            if self.quirks.shifting then
                local value = self.registers[x]
                self.registers[x] = Bit.rshift(value, 1)
                self.registers[0xF] = Bit.band(value, 0x01)
            else
                local value = self.registers[y]
                self.registers[x] = Bit.rshift(value, 1)
                self.registers[0xF] = Bit.band(value, 0x01)
            end
        elseif Bit.band(opcode, 0x000F) == 7 then
            -- Set Vx = Vy - Vx, set VF = 0 on borrow
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            if self.registers[y] >= self.registers[x] then
                self.registers[x] = Bit.band(self.registers[y] - self.registers[x], 0xFF)
                self.registers[0xF] = 1
            else
                self.registers[x] = Bit.band(self.registers[y] - self.registers[x], 0xFF)
                self.registers[0xF] = 0
            end
        elseif Bit.band(opcode, 0x000F) == 0xE then
            -- Set VF = most significant bit of Vx, then Vx = Vx << 1
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            if self.quirks.shifting then
                local value = self.registers[x]
                self.registers[x] = Bit.band(Bit.lshift(value, 1), 0xFF)
                self.registers[0xF] = Bit.band(Bit.rshift(value, 7), 0x1)
            else
                local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
                local value = self.registers[y]
                self.registers[x] = Bit.band(Bit.lshift(value, 1), 0xFF)
                self.registers[0xF] = Bit.band(Bit.rshift(value, 7), 0x1)
            end
        else
            print("Unknown opcode: " .. string.format("0x%04X", opcode))
        end
    elseif opcode >= 0x9000 and opcode < 0xA000 then -- 9XY0
        -- Skip next instruction if Vx != Vy
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
        if self.registers[x] ~= self.registers[y] then
            self.pc = self.pc + 2
        end
    elseif opcode >= 0xA000 and opcode < 0xB000 then -- ANNN
        -- Set I = nnn
        local nnn = Bit.band(opcode, 0x0FFF)
        self.I = nnn
    elseif opcode >= 0xB000 and opcode < 0xC000 then -- BNNN
        if self.quirks.jumping then
            -- BXNN (SuperCHIP quirk): Jump to location nnn + Vx
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local nnn = Bit.band(opcode, 0x0FFF)
            self.pc = nnn + self.registers[x]
        else
            -- Jump to location nnn + V0
            local nnn = Bit.band(opcode, 0x0FFF)
            self.pc = nnn + self.registers[0]
        end
    elseif opcode >= 0xC000 and opcode < 0xD000 then -- CXNN
        -- Set Vx = random byte AND NN
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local nn = Bit.band(opcode, 0x00FF)
        self.registers[x] = Bit.band(math.random(0, 255), nn)
    elseif opcode >= 0xD000 and opcode < 0xE000 then -- DXYN
        if self.mode == self.modes.chip8 then
            -- Draw sprite at coordinate (Vx, Vy) with N bytes of sprite data
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            local n = Bit.band(opcode, 0x000F)

            local vx = self.registers[x] % 64
            local vy = self.registers[y] % 32

            self.registers[0xF] = 0 -- Clear VF

            for i = 0, n - 1 do
                local byte = self.memory[self.I + i]
                for j = 0, 7 do
                    local pixel = Bit.band(byte, Bit.lshift(1, 7 - j))
                    if pixel ~= 0 then
                        local px = vx + j
                        local py = vy + i

                        if self.quirks.clipping then
                            -- Solo dibujamos si está dentro de los límites
                            if px >= 64 or py >= 32 then
                                goto continue
                            end
                        end

                        px = px % 64
                        py = py % 32

                        local idx = py * 64 + px
                        if self.display[idx] == 1 then
                            self.registers[0xF] = 1
                        end
                        self.display[idx] = Bit.bxor(self.display[idx] or 0, 1)
                        ::continue::
                    end
                end
            end
        elseif self.mode == self.modes.superChip then
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local y = Bit.band(Bit.rshift(opcode, 4), 0x0F)
            local n = Bit.band(opcode, 0x000F)

            local vx = self.registers[x] % 128
            local vy = self.registers[y] % 64

            self.registers[0xF] = 0 -- Clear VF

            if n == 0 then
                -- DXY0: Dibuja sprite 16x16 (32 bytes)
                for i = 0, 15 do
                    local byte1 = self.memory[self.I + i * 2]
                    local byte2 = self.memory[self.I + i * 2 + 1]
                    local line = Bit.bor(Bit.lshift(byte1, 8), byte2)
                    for j = 0, 15 do
                        local pixel = Bit.band(line, Bit.lshift(1, 15 - j))
                        if pixel ~= 0 then
                            local px = vx + j
                            local py = vy + i

                            if self.quirks.clipping then
                                -- Si clipping está activado, no dibujamos fuera de pantalla
                                if px >= 128 or py >= 64 then
                                    goto continue
                                end
                            end

                            px = px % 128
                            py = py % 64

                            local idx = py * 128 + px
                            if self.display[idx] == 1 then
                                self.registers[0xF] = 1
                            end
                            self.display[idx] = Bit.bxor(self.display[idx] or 0, 1)
                            ::continue::
                        end
                    end
                end
            else
                -- DXYN: Dibuja sprite 8xN
                for i = 0, n - 1 do
                    local byte = self.memory[self.I + i]
                    for j = 0, 7 do
                        local pixel = Bit.band(byte, Bit.lshift(1, 7 - j))
                        if pixel ~= 0 then
                            local px = vx + j
                            local py = vy + i

                            if self.quirks.clipping then
                                if px >= 128 or py >= 64 then
                                    goto continue
                                end
                            end

                            px = px % 128
                            py = py % 64

                            local idx = py * 128 + px
                            if self.display[idx] == 1 then
                                self.registers[0xF] = 1
                            end
                            self.display[idx] = Bit.bxor(self.display[idx] or 0, 1)
                            ::continue::
                        end
                    end
                end
            end
        else
            print("Unknown opcode: " .. string.format("0x%04X", opcode))
        end
    elseif opcode >= 0xE000 and opcode < 0xF000 then -- EXXX
        local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
        local keyPressed = self.keypad[self.registers[x]] == 1

        if Bit.band(opcode, 0x00FF) == 0x009E then
            -- Skip next instruction if key with value of Vx is pressed
            if keyPressed then
                self.pc = self.pc + 2
            end
        elseif Bit.band(opcode, 0x00FF) == 0x00A1 then
            -- Skip next instruction if key with value of Vx is NOT pressed
            if not keyPressed then
                self.pc = self.pc + 2
            end
        else
            print("Unknown opcode: " .. string.format("0x%04X", opcode))
        end
    elseif opcode >= 0xF000 and opcode < 0x10000 then -- FXNN
        if Bit.band(opcode, 0x00FF) == 0x0007 then
            -- Set Vx = delay timer value
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            self.registers[x] = self.delayTimer
        elseif Bit.band(opcode, 0x00FF) == 0x000A then
            -- Wait for a key press, store the value of the key in Vx
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            self.waitingForKey = true
            self.waitingRegister = x
        elseif Bit.band(opcode, 0x00FF) == 0x0015 then
            -- Set delay timer = Vx
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            self.delayTimer = self.registers[x]
        elseif Bit.band(opcode, 0x00FF) == 0x0018 then
            -- Set sound timer = Vx
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            self.soundTimer = self.registers[x]
        elseif Bit.band(opcode, 0x00FF) == 0x001E then
            -- Set I = I + Vx
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            self.I = self.I + self.registers[x]
        elseif Bit.band(opcode, 0x00FF) == 0x0029 then
            -- Set i to a hex character
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local value = self.registers[x]
            if value > 0xF then
                print("Unknown opcode: " .. string.format("0x%04X", opcode))
            else
                -- Fuente clásica: cada carácter ocupa 5 bytes, empieza en 0x50
                self.I = 0x50 + (value * 5)
            end
        elseif Bit.band(opcode, 0x00FF) == 0x0030 and self.mode == self.modes.superChip then
            -- Set I to the location of the sprite for digit Vx
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local value = self.registers[x]

            if value > 0xF then
                print("Unknown opcode: " .. string.format("0x%04X", opcode))
            else
                -- Fuente extendida: cada carácter ocupa 10 bytes, empieza en 0x100
                self.I = 0x100 + (value * 10)
            end
        elseif Bit.band(opcode, 0x00FF) == 0x0033 then
            -- FX33: Store BCD representation of Vx in memory at I, I+1, and I+2
            local x                 = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            local value             = self.registers[x]
            self.memory[self.I]     = math.floor(value / 100)
            self.memory[self.I + 1] = math.floor((value % 100) / 10)
            self.memory[self.I + 2] = value % 10
        elseif Bit.band(opcode, 0x00FF) == 0x0055 then
            -- Store registers V0 to Vx in memory starting at location I
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            for i = 0, x do
                self.memory[self.I + i] = self.registers[i]
            end
            if self.quirks.memory then
                self.I = self.I + x + 1 -- Increment I by x + 1
            end
        elseif Bit.band(opcode, 0x00FF) == 0x0065 then
            -- Read registers V0 to Vx from memory starting at location I
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            for i = 0, x do
                self.registers[i] = self.memory[self.I + i]
            end
            if self.quirks.memory then
                self.I = self.I + x + 1 -- Increment I by x + 1
            end
        elseif Bit.band(opcode, 0x00FF) == 0x0075 and self.mode == self.modes.superChip then
            -- Store registers V0 to Vx in memory starting at location I (SuperChip)
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
            for i = 0, x do
                self.memory[self.I + i] = self.registers[i]
            end
        elseif Bit.band(opcode, 0x00FF) == 0x0085 and self.mode == self.modes.superChip then
            -- Read registers V0 to Vx from memory starting at location I (SuperChip)
            local x = Bit.band(Bit.rshift(opcode, 8), 0x0F)
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

return chip8
