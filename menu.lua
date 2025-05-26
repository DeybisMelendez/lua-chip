local menu = {
    games = {},
    scrollOffset = 0,
    visibleRows = 10,
    rowHeight = 30,
}
local selected = 1

function menu:onLoad()
    local games = {} -- Asegúrate de inicializar la tabla

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
        if i == selected then
            love.graphics.setColor(1, 1, 0) -- Amarillo
        else
            love.graphics.setColor(1, 1, 1) -- Blanco
        end
        love.graphics.printf(self.games[i], 0, y, love.graphics.getWidth(), "center")
    end
end

function menu:keypressed(key)
    if key == "up" then
        selected = selected - 1
        if selected < 1 then
            selected = #self.games
        end
    elseif key == "down" then
        selected = selected + 1
        if selected > #self.games then
            selected = 1
        end
    elseif key == "return" or key == "kpenter" then
        GamePath = "games/" .. self.games[selected]
        self:setScene("chip8")
    end
end

return menu
