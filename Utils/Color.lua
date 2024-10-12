---@class Color
---@field r number the red of the color
---@field g number the green of the color
---@field b number the blue of the color
---@field h number the hue of the color
---@field s number the saturation of the color
---@field v number the value of the color
---@field state number the state of the color object (0 = HSV, 1 = RGB)
---@param r ?number the red of the color (0-255)
---@param g ?number the green of the color (0-255)
---@param b ?number the blue of the color (0-255)
---@param h ?number the hue of the color (0-1)
---@param s ?number the saturation of the color (0-1)
---@param v ?number the value of the color (0-1)
---@return Color Color the color object
---@section color
function Color(r, g, b, h, s, v)
    return {
        r = r or 0, ---@type number the red of the color
        g = g or 0, ---@type number the green of the color
        b = b or 0, ---@type number the blue of the color
        h = h or 0, ---@type number the hue of the color
        s = s or 0, ---@type number the saturation of the color
        v = v or 0, ---@type number the value of the color
        state = (r and g and b) and 1 or 0, ---@type number the state of the color object (0 = HSV, 1 = RGB)
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
function Color2(a, b, c, setRGB)
    if setRGB then
        return color(a, b, c)
    else
        return color(nil, nil, nil, a, b, c)
    end
end
---@endsection

---Convert the current RGB color to HSV color
---@class Color
---@field convertToHsv function convert the current RGB color to HSV color and set state to HSV
---@param self Color the color object
---@section convertToHsv
function convertToHsv(self)
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
end
---@endsection

---Convert the current HSV color to RGB color
---@class Color
---@field convertToRGB function convert the current HSV color to RGB color and set state to RGB
---@param self Color the color object
---@section convertToRGB
function convertToRGB(self)
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
end
---@endsection

---Returns the RGB values of the color
---@class Color
---@field getRGB function returns the RGB values of the color
---@param self Color the color object
---@return table RGB the RGB values of the color
---@section getRGB
function getRGB(self)
    if self.state == 0 then
        self:convertToRGB()
    end
    return {r = self.r, g = self.g, b = self.b}
end
---@endsection

---Returns the HSV values of the color
---@class Color
---@field getHSV function returns the HSV values of the color
---@param self Color the color object
---@return table HSV the HSV values of the color
---@section getHSV
function getHSV(self)
    if self.state == 1 then
        self:convertToHsv()
    end
    return {h = self.h, s = self.s, v = self.v}
end
---@endsection

---Check if the color is in RGB state
---@class Color
---@field isRGB function check if the color is in RGB state
---@param self Color the color object
---@return boolean boolean True if the color is in RGB state
---@section isRGB
function isRGB(self)
    return self.state == 1
end
---@endsection

---Check if the color is in HSV state
---@class Color
---@field isHSV function check if the color is in HSV state
---@param self Color the color object
---@return boolean boolean True if the color is in HSV state
---@section isHSV
function isHSV(self)
    return self.state == 0
end
---@endsection

---Set the RGB values of the color
---@class Color
---@field setRGB function set the RGB values of the color
---@param self Color the color object
---@param r number the red of the color
---@param g number the green of the color
---@param b number the blue of the color
---@section setRGB
function setRGB(self, r, g, b)
    self.r = r
    self.g = g
    self.b = b
    self.state = 1
end
---@endsection

---Set the HSV values of the color
---@class Color
---@field setHSV function set the HSV values of the color
---@param self Color the color object
---@param h number the hue of the color
---@param s number the saturation of the color
---@param v number the value of the color
---@section setHSV
function setHSV(self, h, s, v)
    self.h = h
    self.s = s
    self.v = v
    self.state = 0
end
---@endsection

---Generate a new hue for the color
---@class Color
---@field genNewHue function generate a new hue for the color at random
---@param self Color the color object
---@section genNewHue
function genNewHue(self)
    self.h = math.random()
end

---Modify the value of the color
---@class Color
---@field modifyValue function modify the value of the color
---@param self Color the color object
---@param offset number the offset to modify the value by
---@section modifyValue
function modifyValue(self, offset)
    self.v = self.v + offset
end
---@endsection

---Generate a new color object with the modified value
---@class Color
---@field getWithModifiedValue function generate a new color object with the modified value
---@param self Color the color object
---@param offset number the offset to modify the value by
---@return Color Color the new color object
---@section getWithModifiedValue
function getWithModifiedValue(self, offset)
    newColor = color(self.r, self.g, self.b)
    newColor:convertToHsv()
    newColor.v = self.v + offset
    return newColor
end
---@endsection

---Set the color as the screen color (RGB)
---@class Color
---@field setAsScreenColor function set the color as the screen color
---@param self Color the color object
---@section setAsScreenColor
function setAsScreenColor(self)
    if self.state == 0 then
        self:convertToRGB()
    end
    screen.setColor(self.r, self.g, self.b)
end
---@endsection

---Get a new color object with the modified hue
---@class Color
---@field getWithModifiedHue function get a new color object with the modified hue
---@param self Color the color object
---@param offset number the offset to modify the hue by
---@return Color Color the new color object
---@section getWithModifiedHue
function getWithModifiedHue(self, offset)
    newColor = color(self.r, self.g, self.b)
    newColor:convertToHsv()
    newColor.h = self.h + offset % 1 --normalize the hue to 0-1
    return newColor
end
---@endsection