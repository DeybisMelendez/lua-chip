local menu = {}
local games = {}
local selected = 1

function menu:onLoad()
    -- Obtener archivos de la carpeta "roms"
    if love.filesystem.getInfo("games") then
        local archivos = love.filesystem.getDirectoryItems("games")
        for _, archivo in ipairs(archivos) do
            table.insert(games, archivo)
        end
    else
        print("Carpeta 'games' no encontrada.")
    end
end

function menu:draw()
    love.graphics.setColor(1, 1, 1) -- Blanco
    love.graphics.printf("Selecciona una ROM y presiona Enter", 0, 10, love.graphics.getWidth(), "center")

    for i, nombre in ipairs(games) do
        local y = 40 + i * 30
        if i == selected then
            love.graphics.setColor(1, 1, 0) -- Amarillo
        else
            love.graphics.setColor(1, 1, 1) -- Blanco
        end
        love.graphics.printf(nombre, 0, y, love.graphics.getWidth(), "center")
    end
end

function menu:keypressed(key)
    if key == "up" then
        selected = selected - 1
        if selected < 1 then
            selected = #games
        end
    elseif key == "down" then
        selected = selected + 1
        if selected > #games then
            selected = 1
        end
    elseif key == "return" or key == "kpenter" then
        GamePath = "games/" .. games[selected]
        self:setScene("chip8")
    end
end

return menu
