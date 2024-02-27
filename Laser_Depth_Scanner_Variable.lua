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

maxLaserFOV = 1
LaserDistances = {}
currentLaserX = 0
currentLaserY = 0
currrentOnScreenLaserX = 0
currrentOnScreenLaserY = 0
Swidth = 64
Sheight = 64
pixelScanSize = 4

ticks = 0
function onTick()
    ticks = ticks + 1
    currentLaserDistance = input.getNumber(3)

    if LaserDistances[currrentOnScreenLaserY] then
        LaserDistances[currrentOnScreenLaserY][currrentOnScreenLaserX] = currentLaserDistance
        -- print(currentLaserDistance .. " Distance at postion: " .. currrentOnScreenLaserX .. "|" .. currrentOnScreenLaserY)
        -- print(LaserDistances[currrentOnScreenLaserY][currrentOnScreenLaserY])
    else
        LaserDistances[currrentOnScreenLaserY] = {}
    end

    currrentOnScreenLaserX = currrentOnScreenLaserX + pixelScanSize
    if currrentOnScreenLaserX > Swidth / pixelScanSize then
        currrentOnScreenLaserX = 0
        currrentOnScreenLaserY = currrentOnScreenLaserY + pixelScanSize
        if currrentOnScreenLaserY > Sheight / pixelScanSize then
            currrentOnScreenLaserY = 0
        end
    end

    currentLaserX = ((maxLaserFOV * 2) * ((currrentOnScreenLaserX * pixelScanSize) / Swidth)) - 1
    currentLaserY = ((maxLaserFOV * 2) * ((currrentOnScreenLaserY * pixelScanSize) / Sheight)) - 1
    output.setNumber(1,currentLaserX)
    output.setNumber(2,currentLaserY)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    for ypos, xarray in pairs(LaserDistances) do
        for xpos, distance in pairs(xarray) do
            --print("Pos: " .. xpos .. "|" .. ypos .. " Distance: " .. distance)
            screen.setColor(255, 0, 0)
            onScreenDrawPosX = xpos * pixelScanSize
            onScreenDrawPosY = ypos * pixelScanSize
            screen.drawRectF(onScreenDrawPosX, onScreenDrawPosY, pixelScanSize, pixelScanSize)
            if onScreenDrawPosX == Swidth or onScreenDrawPosX == 0 or onScreenDrawPosY == Sheight or onScreenDrawPosY == 0 then
                print(string.format("%02d", onScreenDrawPosX) .. "|" .. string.format("%02d", onScreenDrawPosY) .. " Dimensions: " .. Swidth .. "|" .. Sheight .. " Distance: " .. distance)
            end
        end
    end
end
