---this draws lines from the edge of a circle inside with a set length
---@param x number the center of the circle
---@param y number the center of the circle
---@param radius number the radius or length of the indicator
---@param number number the number of indicators in the circle spread in regular intervals
---@param start number the start of the semi circle
---@param rads number the amount of rotation for the semi circle
---@param length number the length of the indicators
function drawSmallLinesAlongCircle(x, y, radius, number, start, rads, length)
    local number = number or 16
    local start = start or 0
    local rads = rads or math.pi * 2
    for i = 1, number do
        ang = start + i * rads / number
        ix = x + (radius - length) * math.cos(ang) --not working		
        iy = y - (radius - length) * math.sin(ang)
        ox = x + radius * math.cos(ang) --working		
        oy = y - radius * math.sin(ang)
        screen.drawLine(ox, oy, ix, iy)
    end
end

---draws a line indicating the value along a semi circle with set parameters
---@param x number the center of the circle
---@param y number the center of the circle
---@param start number the start rads of the circle
---@param rads number the size of the circle
---@param length number the length of the drawn Indicator
---@param value number the current value to be displayed
---@param min number the min value that should be reached
---@param max number the max value that can be reached
function drawIndicatorInCircle(x, y, start, rads, length, value, min, max)
    pct = math.abs(1 - (value - min) / (max - min))
    ang = start + (pct * rads)
    ex = x + length * math.cos(ang)
    ey = y - length * math.sin(ang)
    screen.drawLine(x, y, ex, ey)
end
