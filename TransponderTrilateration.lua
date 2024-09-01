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
    simulator:setScreen(2, "2x2")
    simulator:setScreen(3, "3x3")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(4, screenConnection.touchX)
        simulator:setInputNumber(5, screenConnection.touchY)
    end;
end
---@endsection

require("Utils.TrilaterationUtils")
require("Utils.Utils")

--#region Input Layout
-- Number Inputs:
-- 1: X
-- 2: Y
-- 3: Z
-- 4: Touch X
-- 5: Touch Y
-- 6: Distance

-- Bool Inputs:
-- 1: Active
-- 2: Pulse
-- 3: Touch
--#endregion

beacons = {}
prevBeacon = {x = 0, y = 0}
originGuess = nil
mse = 0
numIterations = 0
MaxBeaconCount = 20
TrilaterationSteps = 500
TrilaterationThreshold = 5
TrilaterationRate = 0.01
BeaconMinSeperation = 20

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)
    touchX = input.getNumber(4)
    touchY = input.getNumber(5)
    beaconDistance = input.getNumber(6)

    tlActive = input.getBool(1)
    tlPulse = input.getBool(2)
    isDepressed = input.getBool(3)

    if tlActive then
        if distance(prevBeacon, {x = gpsX, y = gpsY}) > BeaconMinSeperation and tlPulse and beaconDistance > 150 then --add a new beacon if the distance is greater than 100 and a new distance is available
            table.insert(beacons, {x = gpsX, y = gpsY, distance = beaconDistance})

            if #beacons > MaxBeaconCount then --remove the oldest beacon if the list is too long to keep the complexity down
                table.remove(beacons, 1)
            end

            prevBeacon = {x = gpsX, y = gpsY}

            if #beacons > 3 then --trilateration only works with 3 or more beacons
                originGuess = (isNan(mse) or isInf(mse) or not originGuess) and averageCoordinate(beacons) or originGuess
                originGuess, mse, numIterations = gradientDescendLoop(TrilaterationRate, TrilaterationThreshold, TrilaterationSteps, beacons, originGuess)
            end
        end
    end
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    screen.drawMap(gpsX, gpsY, 5)
    screen.setColor(0, 255, 0)
    for _, beacon in ipairs(beacons) do
        px, py = map.mapToScreen(gpsX, gpsY, 5,  Swidth, Sheight, beacon.x, beacon.y)
        screen.drawRectF(px, py, 2, 2)
    end

    screen.setColor(255, 0, 0)
    if originGuess then
        px, py = map.mapToScreen(gpsX, gpsY, 5,  Swidth, Sheight, originGuess.x, originGuess.y)
        screen.drawCircle(px, py, 5)
    end

    screen.setColor(255, 255, 255)
    screen.drawText(2, 2, "MSE: " .. string.format("%.2f", mse))
    screen.drawText(2, 9, "N: " .. numIterations)
    screen.drawText(2, 16, "B: " .. #beacons)

    if originGuess then
        screen.drawText(2, 23, "X: ", originGuess.x)
        screen.drawText(2, 30, "Y: ", originGuess.y)
    end
end