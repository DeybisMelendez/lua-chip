local scene = require("scene")

GamePath = ""
Quirks = {
    shiftQuirk = false, -- Si es true, se aplica el quirk de shift
}

Bit = require "bit"
function love.load()
    scene:setScene("menu")
end

function love.draw()
    if scene.draw then
        scene:draw()
    end
end

function love.update(dt)
    if scene.update then
        scene:update(dt)
    end
end

function love.keypressed(key)
    if scene.keypressed then
        scene:keypressed(key)
    end
end

function love.keyreleased(key)
    if scene.keyreleased then
        scene:keyreleased(key)
    end
end
