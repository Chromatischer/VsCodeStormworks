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
    simulator:setScreen(1, "2x1")
    simulator:setProperty("Max Gear", 14)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, simulator:getSlider(1) * 14)
        simulator:setInputNumber(2, simulator:getSlider(2) * 500)
        simulator:setInputNumber(3, 500)
        simulator:setInputNumber(4, simulator:getSlider(3) * 100)
        simulator:setInputNumber(5, simulator:getSlider(4))
        simulator:setInputNumber(6, 0)
        simulator:setInputNumber(7, 1)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require("Utils")
require("Circle_Draw_Utils")
require("draw_additions")
require("Time.timeUtils")

ticks = 0
displayRange = 0
displayEndurance = 0
lastFuel = 0
updateSeconds = 2
last_update_ticks = 0
range = 0
endurance = 0
deltaFuelTable = {}
maxDFTSize = 50
lastGpsX = 0
lastGpsY = 0
function onTick()
    ticks = ticks + 1
    currentGear = input.getNumber(1)
    maxGear = property.getNumber("max Gear")
    isUpshift = getCommaPlaces(currentGear) > 0.5
    fuelLevel = input.getNumber(2)
    fuelCapacity = input.getNumber(3)
    fuelPercentage = fuelLevel / fuelCapacity
    engineTemp = input.getNumber(4)
    batteryLevel = input.getNumber(5)
    gpsX = input.getNumber(6)
    gpsY = input.getNumber(7)

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

    screen.setColor(255, 255, 255)
    shiftStr = isUpshift and "U" or ""
    gearString = string.format("%02d", math.floor(currentGear)) .. shiftStr
    screen.drawText(Swidth / 2 - stringPixelLength(gearString) / 2, 2, gearString)


    --#region Temperature
    totalLength = 20
    screen.drawText(2, Sheight - 6, "T")
    screen.drawLine(2, 3 + (engineTemp / 100) * totalLength, 7, 3 + (engineTemp / 100) * totalLength)
    screen.drawLine(2, 3 + totalLength / 2, 4, 3 + totalLength / 2)
    screen.setColor(255, 0, 0)
    screen.drawLine(2, Sheight - 8, 6, Sheight - 8)
    screen.setColor(0, 100, 255)
    screen.drawLine(2, 2, 6, 2)
    screen.setColor(255, 255, 255)
    --#endregion

    --#region Fuel
    lengthLine = Swidth - 16
    screen.drawLine(8, Sheight - 2, Swidth - 18, Sheight - 2)
    screen.drawLine(8, Sheight - 2, 8, Sheight - 8)
    screen.drawText(Swidth - 6, Sheight - 6, "F")
    screen.drawLine(8 + lengthLine / 2, Sheight - 2, 8 + lengthLine / 2, Sheight - 6)
    screen.drawLine(8 + lengthLine / 4, Sheight - 2, 8 + lengthLine / 4, Sheight - 5)
    screen.drawLine(8 + lengthLine / 4 + lengthLine / 2, Sheight - 2, 8 + lengthLine / 4 + lengthLine / 2, Sheight - 5)
    screen.drawLine(9 + (lengthLine - 2) * math.abs(1-fuelPercentage), Sheight - 2, 9 + (lengthLine - 2) * math.abs(1-fuelPercentage), Sheight - 7)
    screen.setColor(255, 0, 0)
    screen.drawLine(Swidth - 8, Sheight - 2, Swidth - 8, Sheight - 8)
    screen.drawLine(Swidth - 19, Sheight - 2,Swidth - 7, Sheight - 2)
    screen.setColor(255, 255, 255)
    --#endregion

    --#region Battery
    batteryLengthLine = Sheight - 11
    screen.drawLine(Swidth - 2, 2, Swidth - 2, Sheight - 9)
    screen.drawLine(Swidth - 2, 2 + batteryLengthLine / 2, Swidth - 5, 2 + batteryLengthLine / 2)
    screen.drawLine(Swidth - 2, 3 + (batteryLengthLine - 3) * batteryLevel, Swidth - 6, 3 + (batteryLengthLine - 3) * batteryLevel)
    screen.setColor(0, 255, 0)
    screen.drawLine(Swidth - 2, 2, Swidth - 5, 2)
    screen.drawLine(Swidth - 2, 2, Swidth - 2, 8)
    screen.setColor(255, 0, 0)
    screen.drawLine(Swidth - 1, Sheight - 10, Swidth - 6, Sheight - 10)
    screen.drawLine(Swidth - 2, Sheight - 13, Swidth - 2, Sheight - 10)
    --#endregion

    --#region Range and Endurance
    screen.setColor(255, 255, 255)
    if not isInf(displayRange) and not isNan(displayRange) then
        screen.drawText(15, 16, "R:" .. string.format("%03d", math.clamp(math.floor(displayRange / 1000), 0, 999)) .. "KM")
    end
    if not isInf(displayEndurance) and not isNan(displayEndurance) then
        uptimeAsHandM = fractionOfHoursToHoursAndMinutes(displayEndurance / 3600)
    end
    screen.drawText(15, 8, "E:" .. string.format("%02d",uptimeAsHandM.h) .. ":" .. string.format("%02d",uptimeAsHandM.m))
    --#endregion

end
