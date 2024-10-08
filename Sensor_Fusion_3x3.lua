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
    simulator:setProperty("debugRadar", true)

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

require("Utils.Utils")
require("Utils.Radar.radarToGlobalCoordinates")

ticks = 0
cameraInfraredActive = false
pitchSpeed = 0
cameraTargetFOV = 0
cameraZoom = 1
secondaryPivotSpeed = 0
secondaryRotationTarget = 0
lastRotationTarget = 0
secondaryMaxSpeed = 1
secondaryPitchTarget = 0
secondaryPitchMaxSpeed = 1
secondaryRadarHorizontal = true
primaryRadarContacts = {}
secondaryRadarContact = {}
primaryRadarMaxRange = 20000
isRadarDisplay = true
radarDisplayRange = 14
radarDisplayRanges = {500, 1000, 2000, 3000, 4000, 5000, 7000, 9000, 11000, 13000, 15000, 17000, 19000, 21000}
pause_ticks_button = 0
buttons = {{x = 88, y = 2, w = 6, h = 7, string = "+", false, funct = function() radarDisplayRange = radarDisplayRange < #radarDisplayRanges and radarDisplayRange + 1 or radarDisplayRange end},
{x = 88, y = 12, w = 6, h = 7, string = "-", false, funct = function() radarDisplayRange = radarDisplayRange > 1 and radarDisplayRange - 1 or radarDisplayRange end}
}
alternateButtons = {{x = 2, y = 2, w = 6, h = 7, string = "R", false, funct = function() isRadarDisplay = true secondaryRotationTarget = primaryRadarCompas * 360 end},
{x = 2, y = 12, w = 6, h = 7, string = "+", false, funct = function() cameraZoom = cameraZoom < 28 and cameraZoom + 1 or cameraZoom end},
{x = 2, y = 22, w = 6, h = 7, string = "-", false, funct = function() cameraZoom = cameraZoom > 1 and cameraZoom - 1 or cameraZoom end},
{x = 2, y = 33, w = 6, h = 7, string = "<", false, funct = function() secondaryRotationTarget = secondaryRotationTarget - 10 end},
{x = 10, y = 33, w = 6, h = 7, string = ">", false, funct = function() secondaryRotationTarget = secondaryRotationTarget + 10 end}}
primaryContactSelected = 0

function onTick()
    ticks = ticks + 1
    radarPivotCurrent = input.getNumber(1) * 360
    laserDistance = input.getNumber(2)
    secondaryRadarXPos = input.getNumber(3)
    secondaryRadarZPos = input.getNumber(4)
    secondaryRadarYPos = input.getNumber(5)
    secondaryRadarOrientation = input.getNumber(6) * 360
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
    secondaryRadarPitch = input.getNumber(22) * 360

    monitorIsTouched = input.getBool(1)
    primaryActive = input.getBool(2)
    primaryRadarTargetOD = input.getBool(3)
    primaryRadarTargetTD = input.getBool(4)
    secondaryActive = input.getBool(5)
    secondaryRadarTargetDetect = input.getBool(6)

    secondaryRadarHorizontal = property.getBool("Secondary Radar Horizontal")
    if property.getBool("debugRadar") then
        isRadarDisplay = false
    end

    output.setBool(1, cameraInfraredActive)
    output.setNumber(1, pitchSpeed)
    output.setNumber(2, cameraTargetFOV)


    index = math.floor(primaryRadarRotation)
    if primaryRadarTargetOD then
        if not (primaryRadarTargetD <= 0) then
            primaryRadarContacts[index] = radarToGlobalCoordinates(primaryRadarTargetD, primaryRadarTargetA, primaryRadarTargetE, primaryRadarX, primaryRadarY, primaryRadarZ, primaryRadarCompas, primaryRadarPitch)
            primaryRadarContacts[index].d = primaryRadarTargetD
        end
    elseif primaryRadarContacts[index] then
        if primaryRadarContacts[index].age <= 0 then
            primaryRadarContacts[index] = nil
        else
            primaryRadarContacts[index].age = primaryRadarContacts[index].age - 10
        end
    end

    if isRadarDisplay then
        for index, button in ipairs(buttons) do
            if isPointInRectangle(button.x, button.y, button.w and button.w or 6, button.h and button.h or 7, monitorTouchX, monitorTouchY) and monitorIsTouched then
                if pause_ticks_button > 30 then
                    button.funct()
                    pause_ticks_button = 0
                end
                button.pressed = true
            else
                button.pressed = false
            end
        end
        pause_ticks_button = pause_ticks_button + 1
    else
        for index, button in ipairs(alternateButtons) do
            if isPointInRectangle(button.x, button.y, button.w and button.w or 6, button.h and button.h or 7, monitorTouchX, monitorTouchY) and monitorIsTouched then
                if pause_ticks_button > 30 then
                    button.funct()
                    pause_ticks_button = 0
                end
                button.pressed = true
            else
                button.pressed = false
            end
        end
        pause_ticks_button = pause_ticks_button + 1
    end

    for index, contact in ipairs(primaryRadarContacts) do
        if contact.displayX and contact.displayY then
            if isPointInRectangle(contact.displayX - 1, contact.displayY - 1, 3, 3, monitorTouchX, monitorTouchY) and monitorIsTouched then
                primaryContactSelected = index
                secondaryRotationTarget = index
                isRadarDisplay = false
            end
        end
    end

    secondaryRotationTarget = math.clamp(secondaryRotationTarget, -90, 90)
    secondaryRotationTarget = lastRotationTarget * 0.99 + secondaryRotationTarget * 0.01
    lastRotationTarget = secondaryRotationTarget
    secondaryRotation = (primaryRadarCompas * 360) - secondaryRadarOrientation
    secondaryPivotSpeed = math.clamp((secondaryRotationTarget - secondaryRotation) / 70, -secondaryMaxSpeed, secondaryMaxSpeed)
    output.setNumber(3, secondaryPivotSpeed)
    secondaryPitchTarget = math.clamp(secondaryPitchTarget, -10, 10)
    pitchSpeed = math.clamp((secondaryRadarPitch - secondaryPitchTarget) / 300, -secondaryPitchMaxSpeed, secondaryPitchMaxSpeed)
    --pitchSpeed = 0
    if isRadarDisplay then
        secondaryRotationTarget = secondaryRadarOrientation
    else
        if secondaryRadarTargetDetect and secondaryRadarTargetD > 50 then
            secondaryRotationTarget = -secondaryRadarTargetA * 360
            secondaryPitchTarget = -secondaryRadarTargetE * 360
        end
    end

    cameraTargetFOV = 1-(2*(180/math.pi)*(math.atan(math.tan((math.pi/180)*(70/2.0))/cameraZoom)))/(135-1.43)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    if isRadarDisplay then
        screen.setColor(0, 0, 0, 255)
        screen.drawRectF(0, 0, Swidth, Sheight)

        radarDisplaySquareStartX = 2
        radarDisplaySquareStartY = 2
        radarDisplaySize = math.min(Swidth, Sheight) - 14
        radarCenterX = radarDisplaySquareStartX + radarDisplaySize / 2
        radarCenterY = radarDisplaySquareStartY + radarDisplaySize / 2
        screen.setColor(100, 100, 100)
        screen.drawRect(radarDisplaySquareStartX, radarDisplaySquareStartY - 1, radarDisplaySize, radarDisplaySize / 2 + 1)
        screen.setColor(240, 115, 10)

        realRadarDisplayRange = radarDisplayRanges[radarDisplayRange]
        --#region radar shit
        i = 0
        m = 0
        for iterator, contact in pairs(primaryRadarContacts) do
            u0 = (contact.x - primaryRadarX) / realRadarDisplayRange --the distance to the target on the X axis divided by the display range
            v0 = (primaryRadarY - contact.y) / realRadarDisplayRange --distance on the Y axis
            u, v = uvCoordinatesOntoUnitCircle(u0, v0) --maps the points onto the unit circle very cool shit!
            if u0 >= -1 and u0 <= 1 and v0 >= -1 and v0 <= 1 then --emergency check
                x, y = fgSquircularMapping(u, v) -- only the offset that has to be added
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
                    screen.setColor(240, 115, 10, (contact.age / 100) * 255)
                    screen.drawRectF(x, y, 2, 2) --drawing it to the screen
                    primaryRadarContacts[iterator].displayX = x
                    primaryRadarContacts[iterator].displayY = y
                    screen.drawText(0, radarCenterY + 9, "x:" .. math.floor(primaryRadarContacts[iterator].displayX) .. " y:" .. math.floor(primaryRadarContacts[iterator].displayY))
                    screen.drawText(0, radarCenterY + 16, iterator)
                end
            end
            --if m <= 5 then
            --    if v0 >= -1 and v0 <= 0 then
            --        screen.drawText(0, radarCenterY + 23 + m * 14, "b:" .. string.format("%.2f", u0) .. " j:" .. string.format("%.2f", v0))
            --        screen.drawText(0, radarCenterY + 30 + m * 14, "u:" .. string.format("%.2f", u) .. " v:" .. string.format("%.2f", v))
            --        m = m + 1
            --    end
            --end
        end
        --#endregion

        screen.setColor(240, 115, 10)
        if realRadarDisplayRange >= 1000 then
            screen.drawText(2, radarCenterY + 2, math.floor(realRadarDisplayRange / 1000) .. "KM")
        else
            screen.drawText(2, radarCenterY + 2, math.floor(realRadarDisplayRange) .. "M")
        end

        --#region radar rotation line
        radarDisplayRotation = primaryRadarRotation / 90
        radarDisplayRotation, _ = uvCoordinatesOntoUnitCircle(radarDisplayRotation, 0)
        x, _ = fgSquircularMapping(radarDisplayRotation, 0)

        radarDisplayRotationX = radarDisplaySquareStartX + radarDisplaySize / 2 + x * radarDisplaySize / 2
        screen.drawLine(radarDisplayRotationX, radarDisplaySquareStartY, radarDisplayRotationX, radarDisplaySquareStartY + radarDisplaySize / 2)
        --#endregion

        for index, button in ipairs(buttons) do
            drawButton(button.x, button.y, button.w, button.h, button.string, button.pressed)
        end

    else
        screen.setColor(0, 255, 0)
        screen.drawText(Swidth - 20, 2, string.format("%02d", math.floor(cameraZoom)) .. "x")
        if secondaryRadarTargetDetect then
            screen.drawText(Swidth - 20, 9, math.floor(secondaryRadarTargetD))
            screen.drawText(Swidth - 20, 16, math.floor(secondaryRotationTarget - secondaryRotation * 10) / 10)
            screen.drawText(Swidth - 24, 23, math.floor(secondaryPivotSpeed * 100) / 100)
        end

        screen.setColor(255, 0, 0)
        if not secondaryActive and (ticks % 100) / 100 > 0.5 then
            screen.drawText(Swidth / 2 - 8, Sheight / 2 - 2, "RDR-OFF")
        end

        for index, button in ipairs(alternateButtons) do
            drawButton(button.x, button.y, button.w, button.h, button.string, button.pressed)
        end
    end

end