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

---draws a simplistic but great looking button to the screen
---@param x number the screen x position for the button
---@param y number the screen y position for the button
---@param w number the width of the button to draw (6 for single char)
---@param h number the height of the button to draw (7 for single char)
---@param string string the text to draw inside of the button
---@param pressed boolean wheather or not the button is being pressed
function drawButton(x,y,w,h,string,pressed)
    w = w or 6
    h = h or 7
    screen.setColor(90,90,90)
    screen.drawRect(x-1,y-1,w+1,h+1)
    if pressed then
        screen.setColor(255,100,100)
    else
        screen.setColor(100,100,100)
    end
    screen.drawRectF(x,y,w,h)
    screen.setColor(240,115,10)
    screen.drawText(x+1,y+1,string)
end

---Converts a bunch of information and the radar contact data to the global position of the radar contact
---@param contactDistance number the contact distance from the radar composite
---@param contactYaw number the contact azimuth from the radar composite
---@param contactPitch number the contact pitch from the radar composite
---@param gpsX number the gps X coordinate of the radar
---@param gpsY number the gps Y coordinate of the radar
---@param gpsZ number the gps Z coordinate of the radar
---@param compas number the compas direction of the vehicle
---@param pitch number the pitch tilt of the vehicle
---@return table numbers the global x, y and z position of the radar contact
function radarToGlobalCoordinates(contactDistance,contactYaw,contactPitch,gpsX,gpsY,gpsZ,compas,pitch)
    globalAngle = math.rad((contactYaw*360 % 360) + compas*-360)
    x = contactDistance * math.sin(globalAngle)
    y = contactDistance * math.cos(globalAngle)
    globalPitch = math.rad((contactPitch*360) + pitch*360)
    z = contactDistance * math.tan(globalPitch)

    return {x=x+gpsX,y=y+gpsY,z=z+gpsZ,age=100}
end

---draws a semi circle
---@param x number center X of the circle
---@param y number center Y of the circle
---@param radius number the radius in pixels of the circle
---@param segments number number of segments the circle should be made of (16 Default)
---@param start number the start point in radians
---@param rads number the size of the circle in radians
function drawCircle(x, y, radius, segments, start, rads)
    --not my code btw
    segments = segments or 16
    start = start or 0
    rads = rads or math.pi * 2

    lx = x + radius * math.cos(start)
    ly = y - radius * math.sin(start)
    for i = 1, segments do --<--this one
        ang = start + i * rads / segments
        px = x + radius * math.cos(ang)
        py = y - radius * math.sin(ang)
        screen.drawLine(px, py, lx, ly)
        lx, ly = px, py
    end
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


---calculate the intersection of two circles if there is one or more using formula from this: https://math.stackexchange.com/a/1033561 post
---@param x1 number the coordinate of the first circles X-Postition
---@param y1 number the coordinate of the first circles Y-Postition
---@param r1 number the radius of the first circle
---@param x2 number the coordinate of the second circles X-Postition
---@param y2 number the coordinate of the second circles Y-Postition
---@param r2 number the radius of the second circle
---@return table intersections a table containing data about: two intersection points as (x1,y1) and (x2,y2)
function circleIntersection(x1,y1,r1,x2,y2,r2)
    d = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    if d > r1 + r2 then
        return {x1 = nil, y1 = nil, x2 = nil, y2 = nil}
    end
    l = (r1^2 - r2^2 + d^2) / (2 * d) --remember? this was your problem :D not putting these parenthesis on the 2*d
    h = math.sqrt(r1^2 - l^2)
    xr1 = (l / d) * (x2 - x1) + (h / d) * (y2 - y1) + x1
    yr1 = (l / d) * (y2 - y1) + (h / d) * (x2 - x1) + y1
    xr2 = (l / d) * (x2 - x1) - (h / d) * (y2 - y1) + x1
    yr2 = (l / d) * (y2 - y1) - (h / d) * (x2 - x1) + y1
    return {x1 = xr1, y1=yr1, x2 = xr2, y2 = yr2}
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