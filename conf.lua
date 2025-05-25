function love.conf(t)
    t.identity = "lua-chip"                       -- Nombre de la carpeta de guardado
    t.version = "11.3"                            -- Versión de LÖVE requerida
    t.console = true                              -- Habilita la consola (útil para debug)

    t.window.title = "Lua Chip - Deybis Melendez" -- Título de la ventana
    t.window.width = 512                          -- Ancho de la ventana
    t.window.height = 256                         -- Alto de la ventana

    t.modules.joystick = false                    -- Habilita el módulo joystick
    t.modules.mouse = false                       -- Habilita el módulo mouse
    t.modules.thread = false                      -- Habilita el módulo hilos
    t.modules.physics = false                     -- Deshabilita el módulo física (actívalo si lo necesitas)
end
