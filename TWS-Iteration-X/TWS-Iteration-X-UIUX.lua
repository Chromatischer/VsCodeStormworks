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
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--The Idea of this project is to seperate the UI / UX layer from the main logic in the other script. The CH multi has to be wired through to the main. All the other data has to be too!

require("Utils.Utils")
require("Utils.DrawAddons")

zoom = 5
zooms = { 0.1, 0.2, 0.5, 1, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50}

buttons = {{x = 0, y = 0, t = "+",    f = function () isUsingCHZoom = false zoom = zoom + 1 < #zooms and zoom + 1 or zoom end},
{x = 0, y = 8, t = "-",               f = function () isUsingCHZoom = false zoom = zoom - 1 > 1 and zoom - 1 or zoom end},
{x = -8, t = "V",                     f = function () screenCenterY = screenCenterY - MapPanSpeed centerOnGPS = false end},
{t = ">",                             f = function () screenCenterX = screenCenterX + MapPanSpeed centerOnGPS = false end},
{x = -16, t = "<",                    f = function () screenCenterX = screenCenterX - MapPanSpeed centerOnGPS = false end},
{x = -8, y = -8, t = "^",             f = function () screenCenterY = screenCenterY + MapPanSpeed centerOnGPS = false end},
{y = -8, t = "C",                     f = function () centerOnGPS = true end},
}

isUsingCHZoom = true
centerOnGPS = true
screenCenterX, screenCenterY = 0, 0
lastPressed = 0
MapPanSpeed = 100
CHGlobalScale = 1
gpsX, gpsY, gpsZ = 0, 0, 0
compas = 0
vesselAngle = 0
CHSel1, CHSel2 = 0, 0
touchX, touchY = 0, 0
radarRotation = 0
CHDarkmode = false
isDepressed = false
SelfIsSelected = false
selfID = 0
lastGlobalScale = 1


ticks = 0
function onTick()
    ticks = ticks + 1
    CHGlobalScale = input.getNumber(1)
    gpsX = input.getNumber(2)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(4)
    compas = input.getNumber(5)
    vesselAngle = (compas * 360) + 180
    CHSel1 = input.getNumber(6)
    CHSel2 = input.getNumber(7)
    touchX = CHSel1 == selfID and input.getNumber(8) or input.getNumber(10)
    touchY = CHSel1 == selfID and input.getNumber(9) or input.getNumber(11)
    radarRotation = (input.getNumber(12) * 360) % 360

    CHDarkmode = input.getBool(1)
    isDepressed = CHSel1 == selfID and input.getBool(2) or input.getBool(3)
    SelfIsSelected = CHSel1 == selfID or CHSel2 == selfID
    selfID = property.getNumber("SelfID")

    output.setNumber(1, gpsX)
    output.setNumber(2, gpsY)
    output.setNumber(3, gpsZ)
    output.setNumber(4, vesselAngle)
    output.setNumber(5, zooms[zoom])
    output.setNumber(6, screenCenterX)
    output.setNumber(7, screenCenterY)
    output.setNumber(8, touchX)
    output.setNumber(9, touchY)
    output.setNumber(10, radarRotation)
    output.setBool(1, isDepressed)
    output.setBool(2, CHDarkmode)
    output.setBool(3, SelfIsSelected)

    if isUsingCHZoom then
        zoom = math.clamp(CHGlobalScale, 1, 21)
    end
    if CHGlobalScale ~= lastGlobalScale then
        isUsingCHZoom = true
    end
    lastGlobalScale = CHGlobalScale

    --#region Setting values on Boot
    if ticks < 10 then
        screenCenterX, screenCenterY = gpsX, gpsY
        lastGlobalScale = CHGlobalScale
    end
    --#endregion

    if centerOnGPS then
        screenCenterX, screenCenterY = gpsX, gpsY
    end

    if isDepressed and ticks - lastPressed > 10 then
        for _, button in ipairs(buttons) do
            if isPointInRectangle(button.x, button.y, button.w and button.w or 8, 8, touchX, touchY) then
                if button.f then
                    button.f()
                end
                lastPressed = ticks
                break
            end
        end
    end

    MapPanSpeed = 100 * zooms[zoom]
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    PanCenter = {x = Swidth - 9, y = Sheight - 9}

    setMapColors(CHDarkmode)
    screen.drawMap(screenCenterX, screenCenterY, zooms[zoom])

    mapGPSX, mapGPSY = map.mapToScreen(screenCenterX, screenCenterY, zooms[zoom], Swidth, Sheight, gpsX, gpsY)
    drawDirectionIndicator(mapGPSX, mapGPSY, CHDarkmode, vesselAngle)


    for _, button in ipairs(buttons) do
        drawCHButton(button, CHDarkmode, PanCenter)
    end
end
