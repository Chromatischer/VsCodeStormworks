require("Utils.Utils")

---Draws the vessel position and rotation to the screen
---@param screenX number the X position on screen to draw the indicator at
---@param screenY number the Y position on screen to draw the indicator at
---@param isDarkMode boolean DarkMode
---@param vesselAngle number the angle of the vessel in degrees
---@section drawDirectionIndicator
function drawDirectionIndicator(screenX, screenY, isDarkMode, vesselAngle)
    setSignalColor(isDarkMode)
    D = {x = screenX, y = screenY}
    alpha = math.rad(vesselAngle)
    beta = math.rad(30)
    smallR = 5
    bigR = 8
    A = translatePoint(alpha, bigR, D)
    B = translatePoint((alpha + 180) + beta, smallR, D)
    C = translatePoint((alpha + 180) - beta, smallR, D)
    screen.drawTriangleF(A.x, A.y, B.x, B.y, D.x, D.y)
    screen.drawTriangleF(A.x, A.y, C.x, C.y, D.x, D.y)
end
---@endsection

---Draws a button on the screen
---At a relative position to the PanCenter defined by: x, y
---
---With a text defined by: t
---
---With a width defined by: w (default is ButtonWidth)
---
---With a color if c is set (signalColor)
---@param button table<x, y, t, w, c>
---@section drawCHButton
function drawCHButton(button, isDarkMode, ButtonWidth, ButtonHeight, PanCenter)
    local localWidth = button.w or ButtonWidth
    button.x = button.x and button.x or PanCenter.x
    button.y = button.y and button.y or PanCenter.y
    button.x = button.x < 0 and PanCenter.x + button.x or button.x
    button.y = button.y < 0 and PanCenter.y + button.y or button.y

    if button.c then
        setSignalColor(isDarkMode)
    else
        setColorGrey(100, isDarkMode)
    end
    screen.drawRectF(button.x + 1, button.y + 1, localWidth - 1, ButtonHeight - 1)
    setColorGrey(15, isDarkMode)
    screen.drawRect(button.x, button.y, localWidth, ButtonHeight)
    screen.drawText(button.x + 3, button.y + 2, button.t)
end
---@endsection

---Sets the color of the screen to a shade of grey
---@param value number the value of the grey color
---@param isDarkMode boolean DarkMode
---@section setColorGrey
function setColorGrey(value, isDarkMode)
    val = isDarkMode and ((value - 50 > 5) and value - 50 or 5) or value
    screen.setColor(val, val, val)
end
---@endsection

---Sets the color as the signal color
---@param isDarkMode boolean DarkMode
---@section setSignalColor
function setSignalColor(isDarkMode)
    setColorFromTable(isDarkMode and {10, 50, 10} or {200, 75, 75})
end
---@endsection

---Sets the color of the screen to the color given in the table
---@param color table<r, g, b, a> the color to set the screen to
---@section setColorFromTable
function setColorFromTable(color)
    screen.setColor(color[1], color[2], color[3], color[4] and color[4] or 255)
end
---@endsection

---Sets the color of the map to dark mode colors
---@section setMapColors
function setMapColors(isDarkMode)
    if isDarkMode then
        screen.setMapColorOcean(0, 0, 0)
        screen.setMapColorShallows(55, 55, 55)
        screen.setMapColorLand(80, 80, 80)
        screen.setMapColorGrass(80, 80, 80)
        screen.setMapColorSand(80, 80, 80)
        screen.setMapColorSnow(80, 80, 80)
    else
        screen.setMapColorOcean(5, 25, 26)
        screen.setMapColorShallows(10, 45, 50)
        screen.setMapColorLand(80, 80, 80)
        screen.setMapColorGrass(40, 70, 26)
        screen.setMapColorSand(107, 88, 21)
        screen.setMapColorSnow(200, 200, 200)
    end
end
---@endsection