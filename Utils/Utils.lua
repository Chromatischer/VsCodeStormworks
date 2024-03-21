---returns wether or not a point XY is within the specified rectangle
---@param rectX number the start of the rectangle
---@param rectY number the end of the rectangle
---@param rectW number the width of the rectangle
---@param rectH number the height of the rectangle
---@param x number the X position of the point to check for
---@param y number the Y position of the point to check for
---@return boolean boolean true if the point is inside the rectangle
function isPointInRectangle(rectX,rectY,rectW,rectH,x,y)
    return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end

---clamps x within min and max
---@param x number the value to clamp
---@param min number the minimum value for x
---@param max number the maximum value for x
---@return number number the clamped value of x within min and max
---@diagnostic disable-next-line: duplicate-set-field
function math.clamp(x,min,max)
    return math.min(math.max(x, min), max)
end

---sets the default map colors for your lua products
function setMapColors()
    screen.setMapColorOcean(0,0,0)
    screen.setMapColorShallows(55,55,55)
    screen.setMapColorLand(80,80,80)
    screen.setMapColorGrass(80,80,80)
    screen.setMapColorSand(80,80,80)
    screen.setMapColorSnow(80,80,80)
end

---returns the length of a string drawn on screen in pixels
---@param string string the string to get the length of
---@return integer length the length in pixels of the string
function stringPixelLength(string)
    return #string * 5
end

---returns the distance between two known points
---@param x1 number the first points X-Coordinate
---@param y1 number the first points Y-Coordinate
---@param x2 number the second points X-Coordinate
---@param y2 number the second points Y-Coordinate
---@return number distance the distance between point A and B
function distanceBetweenPoints(x1,y1,x2,y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end


---check if a number is NAN
---@param number number the number to check for NAN
---@return boolean isNAN wether or not the number is NAN or a number
function isNan(number)
    return number ~= number
end

---check if a number is inf or -inf
---@param number number the number to check
---@return boolean isInfinite true if the number is inf or -inf
function isInf(number)
    return number == math.huge or number == -math.huge
end

---returns the value of value within the bounds min and max
---@param value number the value to use
---@param min number the minimum value
---@param max number the maximum value
---@return number number the position of value within min and max
--- for percent(0, 0, 2) returns 0
---
--- for percent(1, 0, 2) returns 0.5
---
--- for percent(2, 0, 2) returns 1
function percent(value, min, max)
    return (value - min) / (max - min) --changed that
end

function getCommaPlaces(number)
    return number - math.floor(number)
end