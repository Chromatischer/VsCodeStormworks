-- Author: Chromatischer
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

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

require("Utils.Utils")
require("Utils.Color")
require("Utils.DrawAddons")

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

    if centerOnGPS then
        screenCenterX, screenCenterY = gpsX, gpsY
    end

    MapPanSpeed = 100 * zooms[zoom]

    --#region Setting values on Boot
    if ticks < 10 then
        screenCenterX, screenCenterY = gpsX, gpsY
        lastGlobalScale = CHGlobalScale
    end
    --#endregion

    output.setNumber(1, zooms[zoom])
    output.setNumber(2, gpsX)
    output.setNumber(3, gpsY)
    output.setNumber(4, gpsZ)
    output.setNumber(5, vesselAngle)
    output.setNumber(6, touchX)
    output.setNumber(7, touchY)
    output.setNumber(8, beaconDistance)
    output.setNumber(9, screenCenterX)
    output.setNumber(10, screenCenterY)

    output.setBool(1, CHDarkmode)
    output.setBool(2, SelfIsSelected)
    output.setBool(3, isDepressed)
    output.setBool(4, input.getBool(4))

end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    PanCenter = {x = Swidth - 9, y = Sheight - 9}
    setMapColors(CHDarkmode)

    screen.drawMap(screenCenterX, screenCenterY, zooms[zoom])

    for _, button in ipairs(buttons) do
        drawCHButton(button, CHDarkmode, PanCenter)
    end

    setColorGrey(0.1, CHDarkmode)
    screen.drawText(PanCenter.x -18, 18, beaconDistance and beaconDistance > 0 and string.format("%05d", math.floor(math.clamp(beaconDistance, 0, 99999))) or "-----" or "-----")
end
