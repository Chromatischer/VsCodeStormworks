---@section constants
SIGNAL_LIGHT = color(10, 50, 10) ---@type Color
SIGNAL_DARK = color(200, 75, 75) ---@type Color
---@endsection

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
    beta = .52
    A = translatePoint(alpha, 8, D)
    B = translatePoint((alpha + 180) + beta, 5, D)
    C = translatePoint((alpha + 180) - beta, 5, D)
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
function drawCHButton(button, isDarkMode, PanCenter)
   localWidth = button.w or 8
    button.x = button.x and button.x or PanCenter.x
    button.y = button.y and button.y or PanCenter.y
    button.x = button.x < 0 and PanCenter.x + button.x or button.x
    button.y = button.y < 0 and PanCenter.y + button.y or button.y

    if button.c then
        setSignalColor(isDarkMode)
    else
        setColorGrey(0.7, isDarkMode)
    end
    screen.drawRectF(button.x + 1, button.y + 1, localWidth - 1, 8 - 1)
    setColorGrey(0.1, isDarkMode)
    screen.drawRect(button.x, button.y, localWidth, 8)
    screen.drawText(button.x + 3, button.y + 2, button.t)
end
---@endsection

---Sets the color of the screen to a shade of grey
---@param value number the value of the grey color
---@param isDarkMode boolean DarkMode
---@section setColorGrey
function setColorGrey(value, isDarkMode)
    color2(0, 0, isDarkMode and math.max(value - 0.2, 0.1) or value, false):setAsScreenColor()
end
---@endsection

---Sets the color as the signal color
---@param isDarkMode boolean DarkMode
---@section setSignalColor
function setSignalColor(isDarkMode)
    if isDarkMode then
        SIGNAL_DARK:setAsScreenColor()
    else
        SIGNAL_LIGHT:setAsScreenColor()
    end
end
---@endsection

---Sets the color of the map to dark mode colors
---@section setMapColors
function setMapColors(isDarkMode)
    if isDarkMode then
        screen.setMapColorOcean(0, 0, 0)
        screen.setMapColorShallows(20, 20, 20)
        screen.setMapColorLand(30, 30, 30)
        screen.setMapColorGrass(30, 30, 30)
        screen.setMapColorSand(30, 30, 30)
        screen.setMapColorSnow(30, 30, 30)
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