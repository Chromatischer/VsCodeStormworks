-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, 6 - simulator:getSlider(1) * 12) -- speed X
        simulator:setInputNumber(2, 6 - simulator:getSlider(2) * 12) -- speed Y
        simulator:setInputNumber(3, 0.5 - simulator:getSlider(3) * 1) -- vertical speed
    end;
end
---@endsection

require("Utils.Utils")

ticks = 0
function onTick()
    ticks = ticks + 1

    speedX = input.getNumber(1)
    speedY = input.getNumber(2)
    altimeterDiff = input.getNumber(3)

    --print("speed: " .. speed .. " direction: " .. speedDir .. " as Parts: [" .. speedX .. "|" .. speedY .. "]")
end

function onDraw()
    screenCenterX = 48
    screenCenterY = 48
    dirIndicatorLength = 32
    dirIndicatorMinLength = 5
    maxSpeed = 12
    maxVSpeed = 1
    lineAngleGap = 50
    isFullHovering = math.abs(speedX) < 0.1 * maxSpeed and math.abs(speedY) < 0.1 * maxSpeed and math.abs(altimeterDiff) < 0.1 * maxVSpeed

    lineLengthX = math.clamp((math.abs(speedX) / maxSpeed) * dirIndicatorLength, dirIndicatorMinLength, dirIndicatorLength)
    lineLengthX = speedX < 0 and -lineLengthX or lineLengthX
    lineLengthY = math.clamp((math.abs(speedY) / maxSpeed) * dirIndicatorLength, dirIndicatorMinLength, dirIndicatorLength)
    lineLengthY = speedY < 0 and -lineLengthY or lineLengthY
    lineLengthZ = math.clamp((math.abs(altimeterDiff) / maxVSpeed) * dirIndicatorLength, dirIndicatorMinLength, dirIndicatorLength)
    lineLengthZ = altimeterDiff < 0 and lineLengthZ or -lineLengthZ

    screen.setColor(230, 88, 27) -- Red
    x1 = lineLengthX * math.sin(math.rad(lineAngleGap))
    y1 = lineLengthX * math.cos(math.rad(lineAngleGap))
    screen.drawLine(screenCenterX, screenCenterY, screenCenterX + x1, screenCenterY + y1)
    offsetPositionX = speedX > 0 and 1 or -4
    offsetPositionY = speedX > 0 and 1 or -6
    if not isFullHovering then
        screen.drawText(screenCenterX + x1 + offsetPositionX,screenCenterY + y1 + offsetPositionY, "F")
    end

    screen.setColor(18, 232, 98) -- Green
    screen.drawLine(screenCenterX, screenCenterY, screenCenterX, screenCenterY + lineLengthZ)
    offsetZPositionX = altimeterDiff > 0 and -1 or -1
    offsetZPositionY = altimeterDiff > 0 and -6 or 1
    if not isFullHovering then
        screen.drawText(screenCenterX + offsetZPositionX,screenCenterY + lineLengthZ + offsetZPositionY, "H")
    end

    screen.setColor(18, 187, 232) -- Blue
    x2 = lineLengthY * math.sin(math.rad(360 - lineAngleGap))
    y2 = lineLengthY * math.cos(math.rad(360 - lineAngleGap))
    screen.drawLine(screenCenterX, screenCenterY, screenCenterX + x2, screenCenterY + y2)
    offsetYPositionX = speedY > 0 and -5 or 1
    offsetYPositionY = speedY > 0 and 1 or -6
    if not isFullHovering then
        screen.drawText(screenCenterX + x2 + offsetYPositionX,screenCenterY + y2 + offsetYPositionY, "S")
    end

    if isFullHovering then
        screen.setColor(230, 107, 21) -- Yellow
        screen.drawCircle(screenCenterX, screenCenterY, dirIndicatorMinLength)
        screen.drawText(screenCenterX + 6, screenCenterY + 6, "HVR")
        screen.drawLine(screenCenterX - 7, screenCenterY + 7, screenCenterX + 7, screenCenterY - 7)
    end
end
