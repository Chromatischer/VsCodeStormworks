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

--#region CH Layout
-- CH1: Global Scale
-- CH2: GPS X
-- CH3: GPS Y
-- CH4: GPS Z
-- CH5: Vessel Angle
-- CH6: Screen Select I
-- CH7: Screen Select II
-- CH8: Touch X I
-- CH9: Touch Y I
-- CH10: Touch X II
-- CH11: Touch Y II

-- CHB1: Global Darkmode
-- CHB2: Touch I
-- CHB3: Touch II
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
screenCenterX = 0
screenCenterY = 0
selfID = 0
SelfIsSelected = false --whether or not this module is selected by the CH Main Controler
isUsingCHZoom = true
lastGlobalScale = 0

zoom = 5
zooms = {0.1, 0.2, 0.5, 1, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50}

ticks = 0
function onTick()
    ticks = ticks + 1
    selfID = property.getNumber("SelfID")

    CHGlobalScale = input.getNumber(1)
    gpsX = input.getNumber(2)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(4)
    vesselAngle = input.getNumber(5)
    CHSel1 = input.getNumber(6)
    CHSel2 = input.getNumber(7)
    touchX = selfID == CHSel1 and input.getNumber(8) or input.getNumber(10)
    touchY = selfID == CHSel1 and input.getNumber(9) or input.getNumber(11)
    beaconDistance = input.getNumber(12)

    CHDarkmode = input.getBool(1)
    isDepressed = selfID == CHSel1 and input.getBool(2) or input.getBool(3)
    tlActive = input.getBool(4)
    tlPulse = input.getBool(5)

    SelfIsSelected = CHSel1 == selfID or CHSel2 == selfID

    --#region Map Zoom
    if isUsingCHZoom then
        zoom = CHGlobalScale
    end
    if CHGlobalScale ~= lastGlobalScale then
        isUsingCHZoom = true
    end
    lastGlobalScale = CHGlobalScale
    --#endregion

    --#region Beacon Trilateration
    if SelfIsSelected then
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
    --#endregion

    --#region Setting values on Boot
    if ticks < 10 then
        screenCenterX, screenCenterY = gpsX, gpsY
        lastGlobalScale = CHGlobalScale
    end
    --#endregion
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()

    if SelfIsSelected then
        screen.drawMap(gpsX, gpsY, 5)
        screen.setColor(0, 255, 0)
        for _, beacon in ipairs(beacons) do
            px, py = map.mapToScreen(gpsX, gpsY, zooms[zoom], Swidth, Sheight, beacon.x, beacon.y)
            screen.drawRectF(px, py, 2, 2)
        end

        screen.setColor(255, 0, 0)
        if originGuess then
            px, py = map.mapToScreen(gpsX, gpsY, zooms[zoom], Swidth, Sheight, originGuess.x, originGuess.y)
            screen.drawCircle(px, py, (mse / 2000))
        end

        screen.setColor(255, 255, 255)
        --screen.drawText(2, 2, "MSE: " .. string.format("%.2f", mse))
        --screen.drawText(2, 9, "N: " .. numIterations)
        --screen.drawText(2, 16, "B: " .. #beacons)

        if originGuess then
            screen.drawText(2, 2, "X: " .. originGuess.x)
            screen.drawText(2, 9, "Y: " .. originGuess.y)
        end
    end
end