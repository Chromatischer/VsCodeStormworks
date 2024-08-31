---returns wether or not a point XY is within the specified rectangle
---@param rectX number the start of the rectangle
---@param rectY number the end of the rectangle
---@param rectW number the width of the rectangle
---@param rectH number the height of the rectangle
---@param x number the X position of the point to check for
---@param y number the Y position of the point to check for
---@return boolean boolean true if the point is inside the rectangle
---@section isPointInRectangle
function isPointInRectangle(rectX,rectY,rectW,rectH,x,y)
    return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end
---@endsection

---clamps x within min and max
---@param x number the value to clamp
---@param min number the minimum value for x
---@param max number the maximum value for x
---@return number number the clamped value of x within min and max
---@diagnostic disable-next-line: duplicate-set-field
---@section math.clamp addon
---@diagnostic disable-next-line: duplicate-set-field
function math.clamp(x,min,max)
    return math.min(math.max(x, min), max)
end
---@endsection

---sets the default map colors for your lua products
---@section setMapColors
function setMapColors()
    screen.setMapColorOcean(0,0,0)
    screen.setMapColorShallows(55,55,55)
    screen.setMapColorLand(80,80,80)
    screen.setMapColorGrass(80,80,80)
    screen.setMapColorSand(80,80,80)
    screen.setMapColorSnow(80,80,80)
end
---@endsection

---returns the length of a string drawn on screen in pixels
---@param string string the string to get the length of
---@return integer length the length in pixels of the string
---@section getStringPixelLength
function stringPixelLength(string)
    return #string * 5
end
---@endsection

---returns the distance between two known points
---@param x1 number the first points X-Coordinate
---@param y1 number the first points Y-Coordinate
---@param x2 number the second points X-Coordinate
---@param y2 number the second points Y-Coordinate
---@return number distance the distance between point A and B
---@section distanceBetweenPoints
function distanceBetweenPoints(x1,y1,x2,y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end
---@endsection


---check if a number is NAN
---@param number number the number to check for NAN
---@return boolean isNAN wether or not the number is NAN or a number
---@section isNan
function isNan(number)
    return number ~= number
end
---@endsection

---check if a number is inf or -inf
---@param number number the number to check
---@return boolean isInfinite true if the number is inf or -inf
---@section isInf
function isInf(number)
    return number == math.huge or number == -math.huge
end
---@endsection

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
---@section percent
function percent(value, min, max)
    return (value - min) / (max - min) --changed that
end
---@endsection

---smoothly interpolates between values a and b with factor
---@param factor number range 0-1
---@param a number first interpolation number
---@param b number second interpolation number
---@return number number the result of the interpolation
---@section lerp
function lerp(factor, a, b)
    return a + (b - a) * factor
end
---@endsection

---returns the comma places behind the integer (1.5663 -> 0.5663)
---@param number number the float to get the comma places of
---@return number number the non integer part of the number
---@section getCommaPlaces
function getCommaPlaces(number)
    return number - math.floor(number)
end
---@endsection

---returns the pixel length of a distance on the screen!
---@param scale number the scale factor set on the drawMap function
---@param screenWidth number the width of the screen
---@param screenHeight number the height of the screen
---@param distance number the distance in meters
---@return number number the number of pixels the given distance corresponds to on the screen
---@section onMapDistance
function onMapDistance(scale, screenWidth, screenHeight, distance)
    return (distance / (scale * 1000)) * math.min(screenWidth, screenHeight) -- I am not sure about the math.min part tbh!
end
---@endsection

---constants
---@section constants
math.piHalf = math.pi / 2
---@endsection

---applies the Exponentail Moving Average on the value a and b where
---@param a number is the new value
---@param b number is the old value
---@param f number is the factor of how much impact the new value has on the old one
---@return number number the new EMA
---@section exponentialMovingAverage
function exponentialMovingAverage(a, b, f)
    return a * f + b * (1 - f)
end
---@endsection

---returns the sign of the number 1 if x > 0, -1 if x < 0 and 0 if x = 0
---@param x number the number to get the sign of
---@return number number the sign of the number x
---@section sign
function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end
---@endsection

---@section math.round
---@diagnostic disable-next-line: duplicate-set-field
function math.round(number)
    if number % 1 > 0.4 then
        return math.ceil(number)
    else
        return math.floor(number)
    end
end
---@endsection