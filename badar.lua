--
-- badar
--
-- Copyright (c) 2024 Nabeel
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
local object = require 'libs.classic'
badar = object:extend()

function badar:new(obj)
    obj = obj or {}
    for key, value in pairs(obj) do
        self[key] = value
    end

    self.id = obj.id or 'default id'
    self.x = obj.x or 0
    self.y = obj.y or 0
    self.width = obj.width or 0
    self.height = obj.height or 0
    self.minWidth = obj.minWidth or 0
    self.minHeight = obj.minHeight or 0

    self._style = {
        color = { 1, 1, 1 },
        hoverColor = nil,
        padding = { 0, 0, 0, 0 }, -- top, right, bottom, left
        corner = 0,
        opacity = 1,
        scale = 1,
        visible = true,
        borderWidth = 0,
        borderColor = { 0, 0, 0 }
    }
    self.gap = 0;

    self.hovered = false
    self.pressed = false

    self.globalPosition = { x = 0, y = 0 }
    self.children = obj.children or {}
    self.data = obj.data or nil

    self._hover = {
        onEnter = function(s) end,
        onExit = function(s) end
    }
    self._clickFn = nil;
    self._mouseReleaseFn = function() end;
    self._updateFn = function() end;
    self.drawSelf = function()
        local drawRectangle = function(mode)
            love.graphics.rectangle(
                mode,
                math.round(-self.width / 2),
                math.round(-self.height / 2),
                math.round(self.width),
                math.round(self.height),
                self._style.corner,
                self._style.corner
            )
        end
        love.graphics.push()
        love.graphics.translate(math.round(self.x + self.width / 2), math.round(self.y + self.height / 2))
        love.graphics.scale(self._style.scale, self._style.scale)
        drawRectangle('fill')

        -- drawing border
        if self._style.borderWidth > 0 then
            love.graphics.setColor(self._style.borderColor)
            love.graphics.setLineWidth(self._style.borderWidth)
            drawRectangle('line')
            love.graphics.setLineWidth(1)
        end
        love.graphics.pop()
    end
    self.setColor = function()
        local color = self._style.color
        if self.hovered and self._style.hoverColor then
            color = self._style.hoverColor
        end
        if color ~= nil then
            love.graphics.setColor({
                color[1],
                color[2],
                color[3],
                self._style.opacity
            })
        end
    end
    return self
end

function badar:draw()
    if not self._style.visible then
        return function()
            return self
        end
    end
    self.setColor()
    self.drawSelf()

    return function()
        love.graphics.push()
        love.graphics.translate(math.round(self.x + self._style.padding[4]), math.round(self.y + self._style.padding[1]))
        local sW, sH = love.graphics.getWidth(), love.graphics.getHeight()
        self.globalPosition.x, self.globalPosition.y = love.graphics.inverseTransformPoint(sW, sH)
        self.globalPosition.x = sW - self.globalPosition.x
        self.globalPosition.y = sH - self.globalPosition.y

        for _, child in ipairs(self.children) do
            child:draw()()
        end

        love.graphics.pop()
        return self
    end
end

function badar:content(content)
    assert(type(content) == 'table', 'Badar. Content passed to container must be a table.')
    self.children = content;
    return self;
end

function badar:onHover(hoverLogic)
    for key, value in pairs(hoverLogic) do
        self._hover[key] = value
    end
    return self
end

function badar:onClick(func, mouseButton)
    self._clickFn = func
    self.mouseButton = mouseButton or 1
    self.pressed = true
    return self
end

function badar:getRect()
    return {
        self.globalPosition.x - self._style.padding[4],
        self.globalPosition.y - self._style.padding[1],
        (self.globalPosition.x + self.width - self._style.padding[2]),
        (self.globalPosition.y + self.height - self._style.padding[3])
    }
end

function badar:render()
    return self:draw()()
end

function badar:modify(func)
    func(self)
    return self
end

function badar:isMouseInside()
    local px, py = love.mouse.getX(), love.mouse.getY()
    local rect = self:getRect()

    local x, y, width, height = rect[1], rect[2], rect[3], rect[4]
    return px >= x and px <= width and py >= y and py <= height
end

function badar:handlePress(button, func)
    if self:isMouseInside() and button == self.mouseButton then
        if type(self._clickFn) == "function" then
            if type(func) == "function" then
                func({
                    func = self._clickFn,
                    self = self,
                    id = self.id
                })
            end
        end
    end
    for _, child in ipairs(self.children) do
        child:handlePress(button, func)
    end
end

function badar:mousepressed(btn)
    local events = {}
    self:handlePress(btn, function(data)
        table.insert(events, data)
    end)
    if #events > 1 then
        events[#events].func(events[#events].self)
    elseif #events > 0 then
        events[1].func(events[1].self)
    end
end

function badar:layout(obj)
    self._layout    = {
        direction = obj.direction or nil,
        gap       = obj.gap or 0,
        alignment = obj.alignment or nil,
        justify   = obj.justify or nil,
        centered  = obj.centered or false,
    }

    local offset    = 0
    local layout    = self:calculateLayout()
    local widest    = layout.widest + layout.padding.horizontal
    local highest   = layout.highest + layout.padding.vertical

    local functions = {
        centerContent = function(isCentered, child)
            if isCentered then
                if #self.children > 1 then
                    return print('ERROR: Badar. centered container must have only one child.')
                end
                child.x = math.round((self.width - child.width - layout.padding.horizontal) / 2)
                child.y = math.round((self.height - child.height - layout.padding.vertical) / 2)
            end
        end,
        setDirection = function(direction, child)
            local axis = 'x';
            local dimension = 'width'
            if direction == 'column' then
                axis = 'y';
                dimension = 'height'
            end
            child[axis] = offset;
            offset = offset + child[dimension] + self._layout.gap
        end,
        setAlignment = function(direction, child)
            local axis = 'x'
            local dimension = 'width'
            local paddingAxis = 'horizontal'
            local alignment = self._layout.alignment
            local origin = widest
            if direction == 'row' then
                axis = 'y';
                dimension = 'height'
                paddingAxis = 'vertical'
                origin = highest
            end
            if child[dimension] ~= highest then
                if alignment == 'center' then
                    child[axis] = math.round((origin - child[dimension] - layout.padding[paddingAxis]) / 2)
                end
                if alignment == 'end' then
                    child[axis] = math.round(origin - child[dimension] - layout.padding[paddingAxis])
                end
            end
        end,
        setJustify = function()
            local dimension = 'width'
            local content = layout.contentWidth
            if self._layout.direction == 'column' then
                dimension = 'height'
                content = layout.contentHeight
            end
            if self._layout.justify == 'center' then
                offset = (self[dimension] - content) / 2
            end
            if self._layout.justify == 'end' then
                offset = self[dimension] - content
            end
            if self._layout.justify == 'space-between' then
                self._layout.gap = (self[dimension] - (content - layout.gap)) / (#self.children - 1)
            end
        end,
        setCalculatedWidth = function()
            self.width  = layout.computedWidth;
            self.height = layout.computedHeight;
        end,
        setDimensions = function()
            if self._layout.direction == 'row' then
                self.height = math.max(highest, self.minHeight)
            end
            if self._layout.direction == 'column' then
                self.width = math.max(widest, self.minWidth)
            end
        end,
        handleAutoFill = function(child)
            if child.fill then
                child.width = self.width - layout.contentWidth
                child.x = offset - self.gap
                child.height = math.max(highest, child.height)
                child.height = self.height - highest
            end
        end
    }

    functions.setCalculatedWidth()
    functions.setJustify()

    for _, child in ipairs(self.children) do
        functions.centerContent(self._layout.centered, child)
        functions.setDirection(self._layout.direction, child)
        functions.setAlignment(self._layout.direction, child)
    end

    functions.setDimensions()
    return self
end

function badar:calculateLayout()
    local totalWidth, totalHeight, widest, highest = 0, 0, 0, 0
    for _, child in ipairs(self.children) do
        totalWidth = totalWidth + child.width;
        totalHeight = totalHeight + child.height
        highest = math.max(child.height, highest)
        widest = math.max(child.width, widest)
    end

    local hPadding = self._style.padding[4] + self._style.padding[2]
    local vPadding = self._style.padding[1] + self._style.padding[3]
    local gap = self._layout.gap * (#self.children - 1)

    local contentWidth = (totalWidth + hPadding + gap) * self._style.scale;
    local contentHeight = (totalHeight + vPadding + gap) * self._style.scale

    local minimumWidth = math.max(contentWidth, self.minWidth)
    local minimumHeight = math.max(contentHeight, self.minHeight)


    return {
        highest = highest,
        widest = widest,
        padding = {
            horizontal = hPadding,
            vertical = vPadding
        },
        gap = gap,
        contentWidth = contentWidth,
        contentHeight = contentHeight,
        computedWidth = math.max(minimumWidth, self.width),
        computedHeight = math.max(minimumHeight, self.height)
    }
end

function badar:style(style)
    for key, value in pairs(style) do
        self._style[key] = value
    end
    return self
end

function badar:find(target)
    if self == nil then
        return nil
    end

    if self.id == target then
        return self
    end

    for i, child in ipairs(self.children or {}) do
        local result = child:find(target)
        if result ~= nil then
            return result
        end
    end

    return nil
end

function badar:mousemoved()
    if self:isMouseInside() then
        self.hovered = true
        self._hover.onEnter(self)
        self.mouseEntered = true
    else
        self.hovered = false
        if self.mouseEntered then
            self._hover.onExit(self)
            self.mouseEntered = false
        end
    end
    for _, child in ipairs(self.children) do
        child:mousemoved()
    end
end

function badar:mousereleased()
    if self.pressed then
        self:_mouseReleaseFn()
    end
    for _, child in ipairs(self.children) do
        child:mousereleased()
    end
end

function badar:onMouseRelease(func)
    self._mouseReleaseFn = func
    return self
end

function badar:onUpdate(func)
    self._updateFn = func
    return self
end

function badar:update()
    self:_updateFn()
    for _, child in ipairs(self.children) do
        child:update()
    end
end

function badar:resize()
    self:layout({
        direction = self.direction,
        centered = self.centered,
        gap = self.gap,
        alignment = self.alignment,
        justify = self.justify
    })

    for _, child in ipairs(self.children) do
        child:resize()
    end
    return self
end

function math.round(num) return math.floor(num + .5) end

return badar
