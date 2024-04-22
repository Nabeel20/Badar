# Badar 🌕

Badar (Full moon in Arabic) is a declarative, flexbox inspired GUI library for LÖVE 2D.<br>
Badar focuses on composition and reactivity. Container expands based on children dimensions.

### Components

- [tooltip](Components/tooltip.md)
- [text](components/text.lua)

## Installation

The `badar.lua` file should be dropped into an existing project and required by it.<br>
Badar uses [classic](https://github.com/rxi/classic) which simplifies the process of creating your own UI components.

### Usage

```lua
function love.load()
    local container = require 'path.to.badar.lua'

    local button = container({ width = 25, height = 25 }):style({ color = { 1, 0, 0 } })
    local square = container({ width = 10, height = 10 }):style({ color = { 1, 0, 0 }, filled = true })

    main = container({ minWidth = screenWidth, minHeight = screenHeight, hideBorder = true })
        :content({
            square,
            button:onClick(function()
                square:update(function(sq)
                    sq.width = sq.width + 10;
                    return sq
                end)
            end),
        }):style({
            padding = { 16, 16, 16, 16 }
        }):layout({
            direction ='column'
        })
end

function love.draw()
    main:render()
end

function love.mousepressed(x, y, button, istouch)
    main:mousepressed(button)
end
```

## Functions

### Creating a new "container"

```lua
local container = require 'path.to.badar.lua'
local c = container({})
```

- `id`; a string can be used to find targeted notes.
- `x`, `y`; container's position.
- `width`, `height`; container's dimensions.
- `minWidth`, `minHeight`; container's minimum dimensions.
- `drawFunc`; can be used to override default 'rectangle' drawing method (e.g `text` component uses `printf()`)

This function makes a new 'container' that can manage its 'children'. <br>
The container is based on a LÖVE `rectangle`. Space is distributed equally between children if props was not configured.

### `:content({})`

Adds children to container.

### `:find(id (string))`

Search container's children and return child which has the same id.

### `:style({})`

Overrides default container styles. Pass the key you want to override.

```lua
:style({
    color = { 1, 1, 1 },
    padding = { 0, 0, 0, 0 }, -- top, right, bottom, left
    corner = 0, -- corner radius
    opacity = 1,
    filled = false,
    hoverEnabled = false,
    scale = 1
})
```

### `:layout({})`

Aligns children along the main `axis` and along the cross axis using `alignment`, whereas `justify` can be used to align child (not its children) on its parent main axis. <br>

```lua
:layout({
    direction = 'row' -- center and column also
    gap = 0,
    alignment = 'center' , -- or end
    justify = 'end' -- or end
})
```

### `:onClick(fn)`

Sets `fn` to be executed when mouse left button is clicked. Container is passed as argument to `fn`.

### `:onHover(fn)`

Sets `fn` to be called when mouse is hovering. Container is passed as argument to `fn`.

### `:update(function(foo) end)`

This function allows for the modification of container properties. Can be used to animate container props (e.g `flux`)

```lua
container():content({children}):update(function(o)
    o._style.hoverEnabled= true
end)
```

### `:render()`

This function calls the `draw` function for the container and all of its children.
Should be called within `love.draw` function.

## License

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
