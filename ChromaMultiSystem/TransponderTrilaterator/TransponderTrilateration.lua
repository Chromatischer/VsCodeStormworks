-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x2")
    --simulator:setScreen(1, "2x2")
    --simulator:setScreen(1, "3x3")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(4, screenConnection.touchX)
        simulator:setInputNumber(5, screenConnection.touchY)
        simulator:setInputNumber(1, 3)
    end;
end
---@endsection

require("Utils.Color")
require("Utils.Utils")
require("Utils.TrilaterationUtils")
require("Utils.DrawAddons")

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
BeaconMinSeperation = 20
APOutput = {x = 0, y = 0} --output for the autopilot
APSentActive = false
beaconDistance = 0
SelfIsSelected = false
screenCenterX, screenCenterY = 0, 0
vesselAngle = 0

ticks = 0
function onTick()
    ticks = ticks + 1

    zoom = input.getNumber(1) or 1
    gpsX = input.getNumber(2)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(4)
    vesselAngle = input.getNumber(5)
    touchX = input.getNumber(6)
    touchY = input.getNumber(7)
    beaconDistance = input.getNumber(8)
    screenCenterX = input.getNumber(9)
    screenCenterY = input.getNumber(10)

    CHDarkmode = input.getBool(1)
    SelfIsSelected = input.getBool(2)
    isDepressed = input.getBool(3)
    tlActive = input.getBool(4)
    tlPulse = input.getBool(5)

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
                    originGuess, mse, numIterations = gradientDescendLoop(0.01, 5, 500, beacons, originGuess)
                end
            end
        end
    end
    --#endregion
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()

    if SelfIsSelected then

        screen.setColor(0, 255, 0)
        for _, beacon in ipairs(beacons) do
            px, py = map.mapToScreen(screenCenterX, screenCenterY, zoom, Swidth, Sheight, beacon.x, beacon.y)
            if _ == #beacons then
                screen.drawCircle(px, py, beaconDistance / (zoom * 1000) * Swidth)
            else
                screen.drawRectF(px, py, 2, 2)
            end
        end

        mapGPSX, mapGPSY = map.mapToScreen(screenCenterX, screenCenterY, zoom, Swidth, Sheight, gpsX, gpsY)

        screen.setColor(255, 0, 0)
        if originGuess then
            mapOriginX, mapOriginY = map.mapToScreen(screenCenterX, screenCenterY, zoom, Swidth, Sheight, originGuess.x, originGuess.y)
            screen.drawCircle(mapOriginX, mapOriginY, math.clamp(mse / 2000, 2, 20))
            screen.drawLine(mapGPSX, mapGPSY, mapOriginX, mapOriginY)
            setColorGrey(1, CHDarkmode)
            screen.drawText(2, 2, "X: " .. math.floor(originGuess.x))
            screen.drawText(2, 9, "Y: " .. math.floor(originGuess.y))
        end

        drawDirectionIndicator(mapGPSX, mapGPSY, CHDarkmode, vesselAngle)
    end
end


--DONE: Draw the vessel position and angle (V)
--DONE: Draw current beacon bearing and range line (V)
--DONE: Draw latest beacon circle (V)
--DONE: Implement CHDarkmode as darkmode for the map and the buttons (V)

--DONT: Draw the AP output (I)
--DONT: Draw beacons with descending opacity based on age (II)
--TODO: Draw map zoom setting when changing / always visible (III)
--DONE: Draw the current estimated position as text when available (III) 
--DONT: Draw text when the map is panned (IV)
--DONE: Draw origin max resolution circle (IV)