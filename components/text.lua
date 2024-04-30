local badar = require 'badar'
text = badar:extend()

function text:new(txt, obj)
    obj = obj or {}
    text.super.new(self, obj)
    local textStyle = {
        color = { 0, 0, 0 }, -- default is black
        size = 16,
        fontFamily = 'assets/Poppins-Regular.ttf',
        lineHeight = 1,
        alignment = 'left',
        limit = 1000,
    }
    extend(self._style, textStyle)
    if self._style.fontFamily ~= '' then
        self.font = love.graphics.newFont(self._style.fontFamily, self._style.size)
    else
        self.font = love.graphics.newFont(self._style.size)
    end
    self._text = txt;
    self.glyphWidth = 0

    self.pressed = false;
    self.selection = {
        start  = 0,
        finish = 0,
        width  = 0,
        height = 0,
    }
    if type(txt) == "string" then
        local hPadding = self._style.padding[2] + self._style.padding[4]
        local vPadding = self._style.padding[1] + self._style.padding[3]
        self.width = self.font:getWidth(self._text) + hPadding
        self.height = self.font:getHeight(self._text) + vPadding

        self.drawSelf = function()
            self._style.limit = self.font:getWidth(self._text)
            love.graphics.setFont(self.font)
            self.font:setFilter("nearest", "nearest")
            self.font:setLineHeight(self._style.lineHeight)
            --text
            love.graphics.setColor({
                self._style.color[1],
                self._style.color[2],
                self._style.color[3],
                self._style.opacity
            })
            love.graphics.printf(
                self._text,
                self.x + self._style.padding[4],
                self.y + self._style.padding[1],
                self._style.limit,
                self._style.alignment
            )
        end
    end


    return self
end

function text:style(style)
    text.super.style(self, style)
    if self._style.fontFamily ~= '' then
        self.font = love.graphics.newFont(self._style.fontFamily, self._style.size)
    else
        self.font = love.graphics.newFont(self._style.size)
    end
    self.width = self.font:getWidth(self._text) + self._style.padding[2] + self._style.padding[4]
    self.height = self.font:getHeight(self._text) + self._style.padding[1] + self._style.padding[3]
    return self
end

-- https://github.com/rxi/lume/blob/master/lume.lua
function extend(t, ...)
    for i = 1, select("#", ...) do
        local x = select(i, ...)
        if x then
            for k, v in pairs(x) do
                t[k] = v
            end
        end
    end
    return t
end

return text
