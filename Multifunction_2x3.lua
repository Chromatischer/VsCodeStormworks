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
metersLeftOnTank = 0
uptimeH = 0
trackKilometers = 0

ticks = 0
function onTick()
    ticks = ticks + 1
    fuelLevel = input.getNumber(3) * 0.95 + fuelLevel * 0.05 --using WMA makes the fuel level fluctuate less
    fuelCapacity = input.getNumber(4)
    fuelPercentage = fuelLevel / fuelCapacity * 100
    gpsX = input.getNumber(5)
    gpsY = input.getNumber(6)

    if ticks - last_update_ticks > 120 then --update every two seconds
        last_update_ticks = ticks
        deltaFuel = fuelLevel - lastFuel

        distanceTraveled = distanceBetweenPoints(gpsX, gpsY, lastGpsX, lastGpsY)
        speed = distanceTraveled / 2 --is speed in meters/second
        trackKilometers = trackKilometers + (distanceTraveled / 1000) --because the total is being checked

        fuelPerMeter = -deltaFuel / distanceTraveled -- -delta fuel because that should result in a positive value
        fuelPerMeter = (not isNan(fuelPerMeter) and not isInf(fuelPerMeter)) and fuelPerMeter or 0 --additional check for infinite or nan numbers!
        metersLeftOnTank = fuelPerMeter * fuelLevel -- l/m * l should not return m but ill try anyway
        uptimeH = (deltaFuel / 2) * fuelLevel / 3600 -- first converting to l/s then multiply by l and / 60*60=3600 to convert to Hours
        lastFuel = fuelLevel
    end
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()
    screen.setColor(90,90,90)
    screen.drawRect(0,0,Swidth-1,Sheight-1)
    screen.drawRect(0,0,47,9*5)
    screen.drawRect(Swidth-49,0,49,45)

    --#region speed dial indicator
    speedFactor = math.clamp(speed/maxSpeed,0.15,1)
    startRads = math.pi * (1/2) - math.pi * speedFactor
    lengthRads = math.pi * 2 * speedFactor
    drawCircle(72,23,21,16,startRads,lengthRads)
    speedText = "SPEED"
    screen.setColor(240,115,10)
    screen.drawLine(61,24,83,24)
    screen.drawText(72 - stringPixelLength(speedText)/2, 18, speedText)
    formatedSpeed = string.format("%03d",math.floor(speed)) .. "KN"
    screen.drawText(72 - stringPixelLength(formatedSpeed)/2, 26, formatedSpeed)
    --#endregion


    --#region text drawing
    screen.setColor(240, 115, 10)
    screen.drawText(2, 2, "FUEL:" .. string.format("%03d", math.floor(fuelPercentage)) .. "%")
    screen.drawText(2, 9, "RNGE:" .. string.format("%02d", math.floor(metersLeftOnTank / 1000)) .. "KM")
    uptimeAsHandM = fractionOfHoursToHoursAndMinutes(uptimeH)
    screen.drawText(2, 16, "TIME:" .. uptimeAsHandM.h .. ":" .. uptimeAsHandM.m)
    screen.drawText(2, 23, "TRCK:" .. string.format("%02d", math.floor(trackKilometers)) .. "KM")
    --#endregion
end
