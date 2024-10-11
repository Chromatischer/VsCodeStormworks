---@class Color
---@field r number the red of the color
---@field g number the green of the color
---@field b number the blue of the color
---@field h number the hue of the color
---@field s number the saturation of the color
---@field v number the value of the color
---@field state number the state of the color object (0 = HSV, 1 = RGB)
---@field convertToHsv function convert the current RGB color to HSV color
---@field convertToRGB function convert the current HSV color to RGB color
---@field getRGB function get the RGB values of the color
---@field setRGB function set the RGB values of the color
---@field setHSV function set the HSV values of the color
---@field genNewHue function generate a new hue for the color
---@field getWithModifiedValue function returns a new color object with the modified value
---@field setAsScreenColor function set the color as the screen color (RGB)
---@field getWithModifiedHue function returns a new color object with the modified hue
---@param r ?number the red of the color (0-255)
---@param g ?number the green of the color (0-255)
---@param b ?number the blue of the color (0-255)
---@param h ?number the hue of the color (0-1)
---@param s ?number the saturation of the color (0-1)
---@param v ?number the value of the color (0-1)
---@return Color Color the color object
---@section Color
function color(r, g, b, h, s, v)
    return {
        r = r or 0, ---@type number the red of the color
        g = g or 0, ---@type number the green of the color
        b = b or 0, ---@type number the blue of the color
        h = h or 0, ---@type number the hue of the color
        s = s or 0, ---@type number the saturation of the color
        v = v or 0, ---@type number the value of the color
        state = (r and g and b) and 1 or 0, ---@type number the state of the color object (0 = HSV, 1 = RGB)

        ---Convert the current RGB color to HSV color
        ---@param self Color the color object
        convertToHsv = function (self)
            r, g, b = self.r / 255, self.g / 255, self.b / 255
            cmax, cmin = math.max(r, g, b), math.min(r, g, b)
            delta = cmax - cmin

            if delta == 0 then
                h = 0
            elseif cmax == r then
                h = 60 * (((g - b) / delta) % 6)
            elseif cmax == g then
                h = 60 * (((b - r) / delta) + 2)
            else
                h = 60 * (((r - g) / delta) + 4)
            end

            self.h, self.s, self.v = h / 360, (cmax == 0) and 0 or (delta / cmax), cmax
            self.state = 0
        end,

        ---Convert the current HSV color to RGB color
        ---@param self Color the color object
        convertToRGB = function (self)
            --convert the current HSV color to RGB color
            h, s, v = self.h * 360, self.s, self.v
            c = v * s
            x = c * (1 - math.abs((h / 60) % 2 - 1))
            m = v - c

            if h < 60 then
                r, g, b = c, x, 0
            elseif h < 120 then
                r, g, b = x, c, 0
            elseif h < 180 then
                r, g, b = 0, c, x
            elseif h < 240 then
                r, g, b = 0, x, c
            elseif h < 300 then
                r, g, b = x, 0, c
            else
                r, g, b = c, 0, x
            end

            self.r = (r + m) * 255
            self.g = (g + m) * 255
            self.b = (b + m) * 255
            self.state = 1
        end,

        ---Get the RGB values of the color
        ---@param self Color the color object
        ---@return table RGB the RGB values of the color
        getRGB = function (self)
            if self.state == 0 then
                self:convertToRGB()
            end
            return {r = self.r, g = self.g, b = self.b}
        end,

        ---Set the RGB values of the color
        ---@param self Color the color object
        ---@param r number the red of the color
        ---@param g number the green of the color
        ---@param b number the blue of the color
        setRGB = function (self, r, g, b)
            self.r = r
            self.g = g
            self.b = b
            self.state = 1
        end,

        ---Set the HSV values of the color
        ---@param self Color the color object
        ---@param h number the hue of the color
        ---@param s number the saturation of the color
        ---@param v number the value of the color
        setHSV = function (self, h, s, v)
            self.h = h
            self.s = s
            self.v = v
            self.state = 0
        end,

        ---Generate a new hue for the color
        ---@param self Color the color object
        genNewHue = function (self)
            self.h = math.random()
        end,

        ---Get a new color object with the modified value
        ---@param self Color the color object
        ---@param offset number the offset to modify the value by
        ---@return Color Color the new color object
        getWithModifiedValue = function (self, offset)
            newColor = color(self.r, self.g, self.b)
            newColor:convertToHsv()
            newColor.v = self.v + offset
            return newColor
        end,

        ---Set the color as the screen color (RGB)
        ---@param self Color the color object
        setAsScreenColor = function (self)
            if self.state == 0 then
                self:convertToRGB()
                self.state = 0 --reset state to HSV after conversion because setting it should not change the state
            end
            screen.setColor(self.r, self.g, self.b)
        end,

        ---Get a new color object with the modified hue
        ---@param self Color the color object
        ---@param offset number the offset to modify the hue by
        ---@return Color Color the new color object
        getWithModifiedHue = function (self, offset)
            newColor = color(self.r, self.g, self.b)
            newColor:convertToHsv()
            newColor.h = self.h + offset % 1 --normalize the hue to 0-1
            return newColor
        end
    }
end
---@endsection

---Create a new color object with the given values as either RGB or HSV
---@param a number the red or hue of the color
---@param b number the green or saturation of the color
---@param c number the blue or value of the color
---@param setRGB boolean if the values are RGB or HSV
---@return Color Color the color object
---@section color2
function color2(a, b, c, setRGB)
    if setRGB then
        return color(a, b, c)
    else
        return color(nil, nil, nil, a, b, c)
    end
end
---@endsection