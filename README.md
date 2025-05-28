# Lua-Chip

**Lua-Chip** es un emulador de [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) y SuperChip (SCHIP) escrito en Lua, diseñado para ejecutarse con [LÖVE2D](https://love2d.org/). Permite cargar y jugar ROMs clásicas y modernas de CHIP-8 y SuperChip, con soporte para diferentes resoluciones, colores y tests.

## Características

- Soporte completo para instrucciones CHIP-8 y SuperChip (SCHIP)
- Interfaz de selección de ROMs desde diferentes carpetas
- Cambio de paleta de colores en tiempo real (`Tab`)
- Soporte para tests y ROMs modernas
- Implementación de quirks y modos de compatibilidad
- Sonido básico (beep)
- Código modular y fácil de extender

## Requisitos

- [LÖVE2D 11.x](https://love2d.org/)
- [LuaBitOp](https://bitop.luajit.org/) (o equivalente, ya incluido como dependencia)
- ROMs de CHIP-8 y SuperChip (no incluidas)

## Estructura del Proyecto

```
lua-chip/
├── chip8.lua        -- Núcleo del emulador
├── scene.lua        -- Sistema de escenas
├── menu.lua         -- Menú de selección de ROMs
├── main.lua         -- Entrada principal para LÖVE2D
├── roms/
│   ├── chip8Classic/
│   ├── superChipClassic/
│   ├── chip8Modern/
│   └── tests/
└── ...
```

## Uso

1. **Coloca tus ROMs** en las carpetas correspondientes dentro de `roms/`.
2. **Ejecuta el emulador** con LÖVE2D:

   ```sh
   love .
   ```

3. **Navega** por el menú con las flechas, selecciona una ROM y presiona `Enter`.
4. Cambia de directorio de ROMs con `Tab`.
5. Cambia la paleta de colores en el juego con `Tab`.
6. Vuelve al menú desde el juego con `Escape`.

## Controles

- **Flechas**: Navegar por el menú
- **Enter**: Seleccionar ROM
- **Tab**: Cambiar carpeta de ROMs / Cambiar paleta de colores en los juegos
- **Escape**: Volver al menú principal
- **Teclado CHIP-8**:  
  ```
  1 2 3 4
  Q W E R
  A S D F
  Z X C V
  ```

## Estado

- **CHIP-8**: Soporte completo para juegos clásicos y modernos
- **SuperChip**: Soporte para sprites 16x16, pantalla extendida, instrucciones SCHIP y quirks

## Créditos

- Desarrollado por Deybis Melendez
- Basado en documentación de [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) y SuperChip
- Depuración con [Chip 8 Test Suite](https://github.com/Timendus/chip8-test-suite)
- Usa [LÖVE2D](https://love2d.org/) y [LuaBitOp](https://bitop.luajit.org/)

---

¡Disfruta ejecutando y probando juegos clásicos y modernos de CHIP-8 y SuperChip en tu propio emulador!

---

## Screenshots

![screenshot 1](https://raw.githubusercontent.com/DeybisMelendez/lua-chip/refs/heads/main/screenshots/1.png)
![screenshot 2](https://raw.githubusercontent.com/DeybisMelendez/lua-chip/refs/heads/main/screenshots/2.png)
![screenshot 3](https://raw.githubusercontent.com/DeybisMelendez/lua-chip/refs/heads/main/screenshots/3.png)
![screenshot 4](https://raw.githubusercontent.com/DeybisMelendez/lua-chip/refs/heads/main/screenshots/4.png)
![screenshot 5](https://raw.githubusercontent.com/DeybisMelendez/lua-chip/refs/heads/main/screenshots/5.png)

**Licencia:** MIT