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
    simulator:setProperty("Secondary Radar Horizontal", false)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(15, screenConnection.touchX)
        simulator:setInputNumber(16, screenConnection.touchY)
        simulator:setInputNumber(7, ((ticks % 200) / 200) * 0.5 - 0.25)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Utils.Utils")
require("Utils.Coordinate.radarToGlobalCoordinates")
require("Utils.Circle_To_Square_Utils")

ticks = 0
cameraInfraredActive = false
targetPitch = 0
cameraTargetFOV = 0
secondaryPivotSpeed = 0
secondaryRadarHorizontal = true
primaryRadarContacts = {}
primaryRadarTime = {}
secondaryRadarContact = {}
primaryRadarMaxRange = 20000
isRadarDisplay = true
radarDisplayRange = 14
radarDisplayRanges = {500, 1000, 2000, 3000, 4000, 5000, 7000, 9000, 11000, 13000, 15000, 17000, 19000, 21000}


function onTick()
    ticks = ticks + 1
    radarPivotCurrent = input.getNumber(1)
    laserDistance = input.getNumber(2)
    secondaryRadarXPos = input.getNumber(3)
    secondaryRadarZPos = input.getNumber(4)
    secondaryRadarYPos = input.getNumber(5)
    secondaryRadarOrientation = input.getNumber(6)
    primaryRadarRotation = input.getNumber(7) * 360
    primaryRadarTargetD = input.getNumber(8)
    primaryRadarTargetA = input.getNumber(9)
    primaryRadarTargetE = input.getNumber(10)
    secondaryRadarOutput = input.getNumber(11) -- problably unused
    secondaryRadarTargetD = input.getNumber(12)
    secondaryRadarTargetA = input.getNumber((secondaryRadarHorizontal and 13 or 14)) -- Radar target Azimuth and elevation have to be swapped due to not being horizontal!
    secondaryRadarTargetE = input.getNumber((secondaryRadarHorizontal and 14 or 13))
    monitorTouchX = input.getNumber(15)
    monitorTouchY = input.getNumber(16)
    primaryRadarX = input.getNumber(17)
    primaryRadarY = input.getNumber(19)
    primaryRadarZ = input.getNumber(18)
    primaryRadarCompas = input.getNumber(20)
    primaryRadarPitch = input.getNumber(21)
    secondaryRadarPitch = input.getNumber(22) -- has to be added to the pitch pivot!

    monitorIsTouched = input.getBool(1)
    primaryActive = input.getBool(2)
    primaryRadarTargetOD = input.getBool(3)
    primaryRadarTargetTD = input.getBool(4)
    secondaryActive = input.getBool(5)
    secondaryRadarTargetD = input.getBool(6)

    secondaryRadarHorizontal = property.getBool("Secondary Radar Horizontal")

    output.setBool(1, cameraInfraredActive)
    output.setNumber(1, targetPitch)
    output.setNumber(2, cameraTargetFOV)
    output.setNumber(3, secondaryPivotSpeed)

    if primaryRadarTargetOD then
        if not (primaryRadarTargetD <= 0) then
            primaryRadarContacts[primaryRadarRotation] = radarToGlobalCoordinates(primaryRadarTargetD, primaryRadarTargetA, primaryRadarTargetE, primaryRadarX, primaryRadarY, primaryRadarZ, primaryRadarCompas, primaryRadarPitch)
            primaryRadarContacts[primaryRadarRotation].d = primaryRadarTargetD
        end
    else
        primaryRadarContacts[primaryRadarRotation] = nil
    end
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    if isRadarDisplay then
        screen.setColor(0, 0, 0, 255)
        screen.drawRectF(0, 0, Swidth, Sheight)

        radarDisplaySquareStartX = 10
        radarDisplaySquareStartY = 10
        radarDisplaySize = math.min(Swidth, Sheight) - 20
        radarCenterX = radarDisplaySquareStartX + radarDisplaySize / 2
        radarCenterY = radarDisplaySquareStartY + radarDisplaySize / 2
        screen.setColor(255, 0, 0)
        screen.drawRect(radarDisplaySquareStartX, radarDisplaySquareStartY, radarDisplaySize, radarDisplaySize / 2)

        realRadarDisplayRange = radarDisplayRanges[radarDisplayRange]
        i = 0
        m = 0
        for iterator, contact in pairs(primaryRadarContacts) do
            u0 = (contact.x - primaryRadarX) / realRadarDisplayRange --the distance to the target on the X axis divided by the display range
            v0 = (primaryRadarY - contact.y) / realRadarDisplayRange --distance on the Y axis
            u, v = uvCoordinatesOntoUnitCircle(u0, v0) --maps the points onto the unit circle very cool shit!
            if u0 >= -1 and u0 <= 1 and v0 >= -1 and v0 <= 1 then --emergency check
                x, y = ellipticalGridMapping(u, v) -- only the offset that has to be added
                --assuming that this x and y also comes in 0.0-1.0 coordinate format ofc!

                x = radarCenterX + x * radarDisplaySize / 2
                y = radarCenterY + y * radarDisplaySize / 2

                --if i == 0 then
                --    screen.drawText(0, radarCenterY + 2, "u: " .. string.format("%.2f", u) .. " v:" .. string.format("%.2f", v))
                --    screen.drawText(0, radarCenterY + 9, "x:" .. math.floor(x) .. " y:" .. math.floor(y))
                --    screen.drawText(0, radarCenterY + 16, contact.d)
                --    --screen.drawText(0, radarCenterY + 23, tostring(math.floor(realRadarDisplayRange)))
                --    i = i + 1
                --end

                if u >= -1 and u <= 1 and v <= 0 and v >= -1 then
                    screen.drawRectF(x, y, 2, 2) --drawing it to the screen
                end
                primaryRadarContacts[iterator].displayX = x
                primaryRadarContacts[iterator].displayY = y
            end
            --if m <= 5 then
            --    if v0 >= -1 and v0 <= 0 then
            --        screen.drawText(0, radarCenterY + 23 + m * 14, "b:" .. string.format("%.2f", u0) .. " j:" .. string.format("%.2f", v0))
            --        screen.drawText(0, radarCenterY + 30 + m * 14, "u:" .. string.format("%.2f", u) .. " v:" .. string.format("%.2f", v))
            --        m = m + 1
            --    end
            --end
        end

        --#region radar rotation line
        radarDisplayRotation = primaryRadarRotation / 90
        radarDisplayRotation, _ = uvCoordinatesOntoUnitCircle(radarDisplayRotation, 0)
        x, _ = ellipticalGridMapping(radarDisplayRotation, 0)

        radarDisplayRotationX = radarDisplaySquareStartX + radarDisplaySize / 2 + x * radarDisplaySize / 2
        screen.drawLine(radarDisplayRotationX, radarDisplaySquareStartY, radarDisplayRotationX, radarDisplaySquareStartY + radarDisplaySize / 2)
        --#endregion

        --debugPoints = {{u = 0, v = 0}, {u = 0, v = 2}, {u = 2, v = 0}, {u = 0, v = -2}, {u = -2, v = 0}, {u = 2, v = 2}, {u = -2, v = -2}, {u = 2, v = -2}, {u = -1, v = 1}}
        --for index, point in ipairs(debugPoints) do
        --    u, v = uvCoordinatesOntoUnitCircle(point.u, point.v)
        --    if u == 0 and v == 0 then
        --        screen.setColor(0, 255, 0)
        --    else
        --        screen.setColor(0, 0, 255)
        --    end
        --    x, y = ellipticalGridMapping(u, v)
        --    --x2, y2 = simpleStretching(point.u, point.v)
        --    --print(tostring(x == x2) .. " " .. tostring(y == y2))
        --    radarCenterX = radarDisplaySquareStartX + radarDisplaySize / 2
        --    radarCenterY = radarDisplaySquareStartY + radarDisplaySize / 2
        --    x = radarCenterX + x * radarDisplaySize / 2
        --    y = radarCenterY + y * radarDisplaySize / 2
        --    if isNan(x) or isNan(y) or isInf(x) or isInf(y) then
        --        print("u: " .. string.format("%.2f", u) .. " v:" .. string.format("%.2f", v) .. " x:" .. math.floor(x) .. " y:" .. math.floor(y) .. " cx:" .. radarCenterX .. " cy:" .. radarCenterY)
        --    end
        --    if v <= 0 then
        --        screen.drawRectF(x, y, 1, 1) --drawing it to the screen
        --        screen.setColor(255, 255, 0)
        --        screen.drawRectF(radarCenterX, radarCenterY, 1, 1)
        --    end
        --end
    else

    end

end
