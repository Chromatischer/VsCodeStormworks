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
    primaryRadarZ = input.getNumber(18)
    primaryRadarY = input.getNumber(19)
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
        primaryRadarContacts[primaryRadarRotation] = radarToGlobalCoordinates(primaryRadarTargetD, primaryRadarTargetA, primaryRadarTargetE, primaryRadarX, primaryRadarY, primaryRadarZ, primaryRadarCompas, primaryRadarPitch)
        primaryRadarContacts[primaryRadarRotation].d = primaryRadarTargetD
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
        screen.setColor(255, 0, 0)
        screen.drawRect(radarDisplaySquareStartX, radarDisplaySquareStartY, radarDisplaySize, radarDisplaySize)

        realRadarDisplayRange = radarDisplayRanges[radarDisplayRange]
        i = 0
        for iterator, contact in pairs(primaryRadarContacts) do
            u = (contact.x - primaryRadarX) / realRadarDisplayRange --the distance to the target on the X axis divided by the display range
            v = (contact.y - primaryRadarY) / realRadarDisplayRange --distance on the Y axis
            x, y = ellipticalDiscToSquare(u, v) -- only the offset that has to be added
            --assuming that this x and y also comes in 0.0-1.0 coordinate format ofc!
            x = x * radarDisplaySize --casting it to the size of the square
            y = y * radarDisplaySize
            if i == 0 then
                screen.drawText(0, 0, "u: " .. string.format("%.2f", u) .. " v:" .. string.format("%.2f", v))
                screen.drawText(0, 7, "x:" .. math.floor(x) .. " y:" .. math.floor(y))
                screen.drawText(0, 14, contact.d)
            end
            screen.drawRectF(radarDisplaySquareStartX + x, radarDisplaySquareStartY + y, 2, 2) --drawing it to the screen
            i = i + 1
            -- holy shit this actually works! I have no fucking clue how or why but it does something! Fixing may be needed later but I am going to sleep!
        end
        debugPoints = {{u = 0, v = 0}, {u = 0, v = 0.5}, {u = 0.5, v = 0}, {u = 0, v = -0.5}, {u = -0.5, v = 0}, {u = 0.5, v = 0.5}, {u = -0.5, v = -0.5}, {u = 0.5, v = -0.5}, {u = -0.5, v = 0.5}}
        for index, point in ipairs(debugPoints) do
            if point.u == 0 and point.v == 0 then
                screen.setColor(0, 255, 0)
            else
                screen.setColor(0, 0, 255)
            end
            x, y = fgSquircularMapping(point.u, point.v)
            --x2, y2 = simpleStretching(point.u, point.v)
            --print(tostring(x == x2) .. " " .. tostring(y == y2))

            radarCenterX = radarDisplaySquareStartX + radarDisplaySize / 2
            radarCenterY = radarDisplaySquareStartY + radarDisplaySize / 2


            x = radarCenterX + x * radarDisplaySize / 2
            y = radarCenterY + y * radarDisplaySize / 2
            if isNan(x) or isNan(y) or isInf(x) or isInf(y) then
                print("u: " .. string.format("%.2f", point.u) .. " v:" .. string.format("%.2f", point.v) .. " x:" .. math.floor(x) .. " y:" .. math.floor(y) .. " cx:" .. radarCenterX .. " cy:" .. radarCenterY)
            end
            screen.drawRectF(x, y, 1, 1) --drawing it to the screen
            screen.setColor(255, 255, 0)
            screen.drawRectF(radarCenterX, radarCenterY, 1, 1)
        end
    else

    end

end
