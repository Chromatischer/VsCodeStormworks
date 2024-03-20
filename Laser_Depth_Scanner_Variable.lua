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
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)
        simulator:setInputNumber(3, ticks % 50)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Utils.Utils")
require("Utils.draw_additions")
maxLaserFOV = 1
laserFOVStepSize = 0.2
LaserDistances = {}
currentLaserX = 0
currentLaserY = 0
pause_ticks_button = 0
Swidth = 64
Sheight = 64
pixelScanSize = 4
maxPixelScanSize = 7
minPixelScanSize = 0
currrentOnScreenLaserX = 0
currrentOnScreenLaserY = 0
doScan = true
VerticalScanMode = false
buttons = {{x=2, y=2, string = "+", funct = function ()
    pixelScanSize = pixelScanSize + 1 < maxPixelScanSize and pixelScanSize + 1 or pixelScanSize
    resetLaserDraw()
end}, {x=2, y=12, string = "-", funct = function ()
    pixelScanSize = pixelScanSize - 1 > minPixelScanSize and pixelScanSize - 1 or pixelScanSize
    resetLaserDraw()
end}, {x=2, y=22, string = "S", funct = function ()
    doScan = not doScan
end}, {x=2, y=33, string = "I", funct = function ()
    maxLaserFOV = maxLaserFOV + laserFOVStepSize <= 1 and maxLaserFOV + laserFOVStepSize or maxLaserFOV
    resetLaserDraw()
end}, {x=2, y=43, string = "D", funct = function ()
    maxLaserFOV = maxLaserFOV - laserFOVStepSize > 0 and maxLaserFOV - laserFOVStepSize or maxLaserFOV
    resetLaserDraw()
end}, {x=2, y=54, string = "V", funct = function ()
    VerticalScanMode = not VerticalScanMode
end}}

ticks = 0
function onTick()
    ticks = ticks + 1
    isPressed = input.getBool(1)
    touchX = input.getNumber(1)
    touchY = input.getNumber(2)
    currentLaserDistance = input.getNumber(3)

    for index, button in ipairs(buttons) do
        if isPointInRectangle(button.x, button.y, button.w and button.w or 6, button.h and button.h or 7, touchX, touchY) and isPressed then
            if pause_ticks_button > 30 then
                button.funct()
                pause_ticks_button = 0
            end
            button.pressed = true
        else
            button.pressed = false
        end
    end
    pause_ticks_button = pause_ticks_button + 1

    if LaserDistances[currrentOnScreenLaserY] then
        LaserDistances[currrentOnScreenLaserY][currrentOnScreenLaserX] = currentLaserDistance
    else
        LaserDistances[currrentOnScreenLaserY] = {}
    end

    if doScan then
        currrentOnScreenLaserX = currrentOnScreenLaserX + pixelScanSize
        if currrentOnScreenLaserX > Swidth then
            currrentOnScreenLaserX = 0
            currrentOnScreenLaserY = currrentOnScreenLaserY + pixelScanSize
            if currrentOnScreenLaserY > Sheight and not VerticalScanMode then
                currrentOnScreenLaserY = 0
            end
        end
    end

    currentLaserY = ((maxLaserFOV * 2) * (currrentOnScreenLaserY / Sheight)) - 1
    currentLaserX = ((maxLaserFOV * 2) * (currrentOnScreenLaserX / Swidth)) - 1
    output.setNumber(2,currentLaserY)
    output.setNumber(1,currentLaserX)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    --#region minimum and maximum distance
    minDistance = math.huge
    maxDistance = -math.huge
    for n, xarray in pairs(LaserDistances) do
        for m, distance in pairs(xarray) do
            minDistance = math.min(minDistance, distance)
            maxDistance = math.max(maxDistance, distance)
        end
    end
    --#endregion

    --#region draw distance to screen
    screen.setColor(0, 0, 0, 255)
    screen.drawClear()
    if not VerticalScanMode then
        for ypos, xarray in pairs(LaserDistances) do
            for xpos, distance in pairs(xarray) do
                colorshift = percent(distance, minDistance, maxDistance) * 1
                screen.setColor(240, 115, 10, (230 * colorshift) + 25)
                screen.drawRectF(xpos, ypos, pixelScanSize, pixelScanSize)
                if xpos == currrentOnScreenLaserX and ypos == currrentOnScreenLaserY then
                    screen.setColor(255, 255, 255)
                    screen.drawRect(currrentOnScreenLaserX - 1, currrentOnScreenLaserY - 1, pixelScanSize + 1, pixelScanSize + 1)
                end
            end
        end
    else
        -- doesnt work but youll figure it out!
        for y = #LaserDistances, #LaserDistances - (Sheight / pixelScanSize), -1 do
            xarray = LaserDistances[y]
            if xarray then
                for x = 1, #xarray, 1 do
                    distance = xarray[x]
                    colorshift = percent(distance, minDistance, maxDistance) * 1
                    screen.setColor(240, 115, 10, (230 * colorshift) + 25)
                    screen.drawRectF(x, y, pixelScanSize, pixelScanSize)
                    if x == currrentOnScreenLaserX and y == currrentOnScreenLaserY then
                        screen.setColor(255, 255, 255)
                        screen.drawRect(currrentOnScreenLaserX - 1, currrentOnScreenLaserY - 1, pixelScanSize + 1, pixelScanSize + 1)
                    end
                end
            end
        end
    end
    --#endregion

    --#region draw buttons
    for u, button in ipairs(buttons) do
        drawButton(button.x,button.y,button.w,button.h,button.string,button.pressed)
    end
    --#endregion
end

function resetLaserDraw()
    currrentOnScreenLaserX = 0
    currrentOnScreenLaserY = 0
    LaserDistances = {}
end
