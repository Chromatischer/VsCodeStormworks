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