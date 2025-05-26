local menu = {
    games = {},
}

function menu:onLoad()
    local games = {} -- Asegúrate de inicializar la tabla
    self.selected = 1
    self.scrollOffset = 0
    self.rowHeight = 30                                                              -- Altura de cada fila
    self.visibleRows = math.floor((love.graphics.getHeight() - 40) / self.rowHeight) -- Ajustar según la altura de la ventana
    if love.filesystem.getInfo("games", "directory") then
        local archivos = love.filesystem.getDirectoryItems("games")
        for _, archivo in ipairs(archivos) do
            -- Verificar que sea un archivo .ch8
            if archivo:match("%.ch8$") then
                local ruta = "games/" .. archivo
                if love.filesystem.getInfo(ruta, "file") then
                    table.insert(games, archivo)
                end
            end
        end
    else
        print("Carpeta 'games' no encontrada.")
    end
    menu.games = games
end

function menu:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Selecciona una ROM y presiona Enter", 0, 10, love.graphics.getWidth(), "center")

    local startIndex = self.scrollOffset + 1
    local endIndex = math.min(#self.games, self.scrollOffset + self.visibleRows)

    for i = startIndex, endIndex do
        local y = 40 + (i - startIndex) * self.rowHeight
        if i == self.selected then
            love.graphics.setColor(1, 1, 0) -- Amarillo
        else
            love.graphics.setColor(1, 1, 1) -- Blanco
        end
        love.graphics.printf(self.games[i], 0, y, love.graphics.getWidth(), "center")
    end
end

function menu:keypressed(key)
    if key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.games
            self.scrollOffset = math.max(#self.games - self.visibleRows, 0) -- ir al final
        end
    elseif key == "down" then
        self.selected = self.selected + 1
        if self.selected > #self.games then
            self.selected = 1
            self.scrollOffset = 0 -- ir al inicio
        end
    elseif key == "return" or key == "kpenter" then
        GamePath = "games/" .. self.games[self.selected]
        self:setScene("chip8")
        return
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
    elseif self.scrollOffset > #self.games - self.visibleRows then
        self.scrollOffset = math.max(#self.games - self.visibleRows, 0)
    end
end

return menu
