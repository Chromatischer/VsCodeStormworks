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
    simulator:setScreen(1, "3x2")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)
        simulator:setInputNumber(3, simulator:getSlider(2)*50000)
        simulator:setInputNumber(4, 50000)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Utils.Utils")
require("Utils.draw_additions")
require("Utils.Time.timeUtils")

formatedSpeed = ""
fuelPercentage = 100
speed = 0
maxSpeed = 100
last_update_ticks = 0
lastGpsX = 0
lastGpsY = 0
fuelLevel = 0
distanceTraveled = 0
lastFuel = 0
fuelPerMeter = 0
range = 0
endurance = 0
trackKilometers = 0
gpsPositions = {}
deltaFuel = 0
deltaFuelTable = {}
maxDFTSize = 50
updateSeconds = 0.5
displayRange = 0
displayEndurance = 0
gpsDataPoints = 50

ticks = 0
function onTick()
    ticks = ticks + 1
    isPressed = input.getBool(1)
    touchX = input.getNumber(2)
    touchY = input.getNumber(3)
    fuelLevel = input.getNumber(3) * 0.9 + fuelLevel * 0.1 --using WMA makes the fuel level fluctuate less
    fuelCapacity = input.getNumber(4)
    fuelPercentage = fuelLevel / fuelCapacity * 100
    gpsX = input.getNumber(5)
    gpsY = input.getNumber(6)

    if #gpsPositions > 1 then
        lastGpsPos = gpsPositions[1]
        if math.abs(distanceBetweenPoints(lastGpsPos.x, lastGpsPos.y, gpsX, gpsY)) > 10 then
            table.insert(gpsPositions, 1, {x = gpsX, y = gpsY})
        end
        if #gpsPositions > gpsDataPoints then
            table.remove(gpsPositions)
        end
    else
        table.insert(gpsPositions, 1, {x = gpsX, y = gpsY})
    end


    if ticks < 10 then
        lastGpsX = gpsX
        lastGpsY = gpsY
    end

    if ticks - last_update_ticks > updateSeconds * 60 then --update every two seconds
        last_update_ticks = ticks

        table.insert(deltaFuelTable, 1, lastFuel - fuelLevel) --adding new values in the beginning of the array
        if #deltaFuelTable > maxDFTSize then
            table.remove(deltaFuelTable) --removing the last and oldest value of the array when it gets to large to prevent infinite growth 
        end

        deltaFuel = 0
        deltaFuels = 0
        for key, deltaFuelFromTable in pairs(deltaFuelTable) do
            deltaFuels = deltaFuels + 1
            deltaFuel = deltaFuel + deltaFuelFromTable
        end
        deltaFuel = deltaFuel / deltaFuels

        distanceTraveled = math.abs(distanceBetweenPoints(gpsX, gpsY, lastGpsX, lastGpsY))
        speed = distanceTraveled / updateSeconds --is speed in meters/second
        trackKilometers = trackKilometers + (distanceTraveled / 1000) --because the total is being checked

        endurance = (fuelLevel / (deltaFuel / updateSeconds)) -- l / l/s should give seconds
        range = speed * endurance -- (m/s * s) should give l
        lastFuel = fuelLevel
        lastGpsX = gpsX
        lastGpsY = gpsY
    end

    --using wma to smooth out transitions between values
    displayRange = displayRange * 0.995 + range * 0.005
    displayEndurance = displayEndurance * 0.995 + endurance * 0.005
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()
    screen.setColor(90,90,90)
    screen.drawRect(0,0,Swidth-1,Sheight-1)
    screen.drawRect(0,0,47,29)
    screen.drawRect(0,29,47,34)
    screen.drawRect(Swidth-49,0,49,45)

    --#region speed dial indicator
    knots = speed * 1.94384
    speedFactor = math.clamp(knots / maxSpeed, 0.15, 1)
    startRads = math.pi * (1/2) - math.pi * speedFactor
    lengthRads = math.pi * 2 * speedFactor
    drawCircle(72,23,21,16,startRads,lengthRads)
    speedText = "SPEED"
    screen.setColor(240,115,10)
    screen.drawLine(60,24,83,24)
    screen.drawText(72 - stringPixelLength(speedText)/2, 18, speedText)
    formatedSpeed = string.format("%03d",math.floor(knots)) .. "KN"
    screen.drawText(72 - stringPixelLength(formatedSpeed)/2, 26, formatedSpeed)
    --#endregion

    --#region text drawing
    screen.setColor(240, 115, 10)
    screen.drawText(2, 2, "FUEL:" .. string.format("%03d", math.floor(fuelPercentage)) .. "%")
    screen.drawText(2, 9, "RNG:" .. string.format("%03d", math.clamp(math.floor(displayRange / 1000), 0, 999)) .. "KM")
    uptimeAsHandM = fractionOfHoursToHoursAndMinutes(displayEndurance / 3600)
    screen.drawText(2, 16, "TME:" .. string.format("%02d",uptimeAsHandM.h) .. ":" .. string.format("%02d",uptimeAsHandM.m))
    screen.drawText(2, 23, "TRK:" .. string.format("%03d", math.clamp(math.floor(trackKilometers), 0, 999)) .. "KM")
    --#endregion

    --#region track drawing
    --TODO: continue working on this track map!
    minX = math.huge
    minY = math.huge
    maxX = -math.huge
    maxY = -math.huge
    for index, trackPoint in ipairs(gpsPositions) do
        minX = math.min(minX, trackPoint.x) --this seams like the best option for that
        minY = math.min(minY, trackPoint.y)
        maxX = math.max(maxX, trackPoint.x)
        maxY = math.max(maxY, trackPoint.y)
    end
    onScreenMinX = 2
    onScreenMaxX = 46
    onScreenMinY = 31
    onScreenMaxY = 62

    screen.setColor(240, 115, 10)
    for i = #gpsPositions - 1, 1, -1 do
        currentPosition = gpsPositions[i]
        lastPosition = gpsPositions[i+1]

        currentGpsOnScreenPositionX = onScreenMinX + (percent(currentPosition.x, minX, maxX) * 44) -- then using the previously calculated value to determine the onscreen position
        currentGpsOnScreenPositionY = onScreenMinY + (percent(currentPosition.y, minY, maxY) * 31)

        lastGpsOnScreenPositionX = onScreenMinX + (percent(lastPosition.x, minX, maxX) * 44) -- then using the previously calculated value to determine the onscreen position
        lastGpsOnScreenPositionY = onScreenMinY + (percent(lastPosition.y, minY, maxY) * 31)
        screen.drawLine(lastGpsOnScreenPositionX, lastGpsOnScreenPositionY, currentGpsOnScreenPositionX, currentGpsOnScreenPositionY)
    end
    --endregion
end
