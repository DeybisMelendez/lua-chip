local menu = {
    roms = {
        {},
        {},
    },
    dir = 1,
}

function menu:onLoad()
    self.selected = 1
    self.scrollOffset = 0
    self.rowHeight = 30                                                              -- Altura de cada fila
    self.visibleRows = math.floor((love.graphics.getHeight() - 40) / self.rowHeight) -- Ajustar según la altura de la ventana

    menu.roms[1] = self:getROMs("games")                                             -- Cargar los juegos desde el directorio "games"
    menu.roms[2] = self:getROMs("tests")                                             -- Cargar los tests desde el directorio "tests"
end

function menu:getROMs(dir)
    local games = {}
    local files = love.filesystem.getDirectoryItems(dir)
    for _, file in ipairs(files) do
        if file:match("%.ch8$") or file:match("%.rom$") then
            table.insert(games, dir .. "/" .. file)
        end
    end

    -- Ordenar los juegos alfabéticamente
    table.sort(games)
    return games
end

function menu:draw()
    love.graphics.clear(0, 0, 0) -- Fondo
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Selecciona una ROM y presiona Enter", 0, 10, love.graphics.getWidth(), "center")

    local startIndex = self.scrollOffset + 1
    local endIndex = math.min(#self.roms[self.dir], self.scrollOffset + self.visibleRows)

    for i = startIndex, endIndex do
        local y = 40 + (i - startIndex) * self.rowHeight
        if i == self.selected then
            love.graphics.setColor(1, 1, 0) -- Amarillo
        else
            love.graphics.setColor(1, 1, 1) -- Blanco
        end
        love.graphics.printf(self.roms[self.dir][i], 0, y, love.graphics.getWidth(), "center")
    end
end

function menu:keypressed(key)
    local roms = self.roms[self.dir]
    if key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #roms
            self.scrollOffset = math.max(#roms - self.visibleRows, 0) -- ir al final
        end
    elseif key == "down" then
        self.selected = self.selected + 1
        if self.selected > #roms then
            self.selected = 1
            self.scrollOffset = 0 -- ir al inicio
        end
    elseif key == "return" or key == "kpenter" then
        GamePath = roms[self.selected]
        self:setScene("chip8")
        return
    elseif key == "tab" then
        self.dir = self.dir == 1 and 2 or 1 -- Cambiar entre juegos y tests
        self.selected = 1                   -- Reiniciar selección al cambiar de directorio
        self.scrollOffset = 0               -- Reiniciar scrollOffset al cambiar de directorio
    end

    -- Ajustar scrollOffset para que la opción seleccionada esté visible
    if self.selected > self.scrollOffset + self.visibleRows then
        self.scrollOffset = self.selected - self.visibleRows
    elseif self.selected <= self.scrollOffset then
        self.scrollOffset = self.selected - 1
    end

    -- Evitar que scrollOffset sea negativo o pase el límite
    if self.scrollOffset < 0 then
        self.scrollOffset = 0
    elseif self.scrollOffset > #roms - self.visibleRows then
        self.scrollOffset = math.max(#roms - self.visibleRows, 0)
    end
end

return menu
