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

require("Utils.TrilaterationUtils")
require("Utils.Utils")
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
centerOnGPS = false
lastPressed = 0
MapPanSpeed = 10
PanCenter = {x = 87, y = 55}
APOutput = {x = 0, y = 0} --output for the autopilot
APSentActive = false
beaconDistance = 0
CHGlobalScale = 1

zoom = 5
zooms = {0.1, 0.2, 0.5, 1, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50}

buttons = {{x = 0, y = 0, t = "+",    f = function () isUsingCHZoom = false zoom = zoom + 1 < #zooms and zoom + 1 or zoom end},
{x = 0, y = 8, t = "-",               f = function () isUsingCHZoom = false zoom = zoom - 1 > 1 and zoom - 1 or zoom end},
{x = -8, t = "V",                     f = function () screenCenterY = screenCenterY - MapPanSpeed centerOnGPS = false end},
{t = ">",                             f = function () screenCenterX = screenCenterX + MapPanSpeed centerOnGPS = false end},
{x = -16, t = "<",                    f = function () screenCenterX = screenCenterX - MapPanSpeed centerOnGPS = false end},
{x = -8, y = -8, t = "^",             f = function () screenCenterY = screenCenterY + MapPanSpeed centerOnGPS = false end},
{y = -8, t = "C",                     f = function () centerOnGPS = true end},
{x = -5, y = 0, t = "AP", w = 13,     f = function () APOutput = originGuess APSentActive = not APSentActive end}, -- if its active, send the output to the AP if not, sent flag is st to false, so no AP will activate
{x = -21, y = 8, t = "CLEAR", w = 29, f = function () beacons = {} originGuess = nil end},
{x = -21, y = 16, t = "", w = 29, c = 0}
}


ticks = 0
function onTick()
    ticks = ticks + 1
    selfID = property.getNumber("SelfID")

    CHGlobalScale = input.getNumber(1)
    gpsX = input.getNumber(2)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(4)
    vesselAngle = (input.getNumber(5) * 360) + 180 -- -0.5 -> 0.5 to 0 -> 360 conversion turns to degrees
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
        zoom = math.clamp(CHGlobalScale, 1, 21)
    end
    if CHGlobalScale ~= lastGlobalScale then
        isUsingCHZoom = true
    end
    lastGlobalScale = CHGlobalScale
    --#endregion

    if centerOnGPS and SelfIsSelected then
        screenCenterX, screenCenterY = gpsX, gpsY
    end

    if SelfIsSelected and isDepressed and ticks - lastPressed > 10 then
        for _, button in ipairs(buttons) do
            if isPointInRectangle(button.x, button.y, button.w or 8, 8, touchX, touchY) then
                if button.f then
                    button.f()
                end
                lastPressed = ticks
                break
            end
        end
    end

    --#region Beacon Trilateration
    if SelfIsSelected then
        MapPanSpeed = 100 * zooms[zoom]
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
    PanCenter = {x = Swidth - 9, y = Sheight - 9}

    if SelfIsSelected then

        setMapColors(CHDarkmode)

        screen.drawMap(screenCenterX, screenCenterY, zooms[zoom])
        screen.setColor(0, 255, 0)
        for _, beacon in ipairs(beacons) do
            px, py = map.mapToScreen(screenCenterX, screenCenterY, zooms[zoom], Swidth, Sheight, beacon.x, beacon.y)
            if _ == #beacons then
                screen.drawCircle(px, py, beaconDistance / (zooms[zoom] * 1000) * Swidth)
            else
                screen.drawRectF(px, py, 2, 2)
            end
        end

        mapGPSX, mapGPSY = map.mapToScreen(screenCenterX, screenCenterY, zooms[zoom], Swidth, Sheight, gpsX, gpsY)

        screen.setColor(255, 0, 0)
        if originGuess then
            mapOriginX, mapOriginY = map.mapToScreen(screenCenterX, screenCenterY, zooms[zoom], Swidth, Sheight, originGuess.x, originGuess.y)
            screen.drawCircle(mapOriginX, mapOriginY, math.clamp(mse / 2000, 2, 20))
            screen.drawLine(mapGPSX, mapGPSY, mapOriginX, mapOriginY)
            setColorGrey(255, CHDarkmode)
            screen.drawText(2, 2, "X: " .. math.floor(originGuess.x))
            screen.drawText(2, 9, "Y: " .. math.floor(originGuess.y))
        end

        drawDirectionIndicator(mapGPSX, mapGPSY, CHDarkmode, vesselAngle)

        for _, button in ipairs(buttons) do
            drawCHButton(button, CHDarkmode, PanCenter)
        end

        setColorGrey(15, CHDarkmode)
        screen.drawText(PanCenter.x -18, 18, beaconDistance and beaconDistance > 0 and string.format("%05d", math.floor(math.clamp(beaconDistance, 0, 99999))) or "-----" or "-----")
    end
end


--DONE: Draw the vessel position and angle (V)
--DONE: Draw current beacon bearing and range line (V)
--DONE: Draw latest beacon circle (V)
--DONE: Implement CHDarkmode as darkmode for the map and the buttons (V)

--TODO: Draw the AP output (I)
--DONT: Draw beacons with descending opacity based on age (II)
--TODO: Draw map zoom setting when changing / always visible (III)
--DONE: Draw the current estimated position as text when available (III) 
--DONT: Draw text when the map is panned (IV)
--DONE: Draw origin max resolution circle (IV)