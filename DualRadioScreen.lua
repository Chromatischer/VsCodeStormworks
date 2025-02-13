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
    simulator:setScreen(1, "2x1")
    simulator:setProperty("radioOneMatrixStr", "1111100100001000010011111")
    simulator:setProperty("radioTwoMatrixStr", "1111101010010100101011111")

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
require("Utils")
require("Color")
require("DrawAddons")
require("Vectors.vec2")
require("MatrixDrawer")

isTransmit = false

ticks = 0
function onTick()
    ticks = ticks + 1
    tx = input.getNumber(1)
    ty = input.getNumber(2)
    chUp = input.getBool(1)
    chDown = input.getBool(2)
    isTouch = input.getBool(3)
    ptt = input.getBool(4)
    sStrength1 = input.getNumber(3)
    sStrength2 = input.getNumber(4)
    sSelected = input.getNumber(5)
    radioOneMatrixStr = property.getText("radioOneMatrixStr")
    radioTwoMatrixStr = property.getText("radioTwoMatrixStr")
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    background = 0.03
    light = 0.5
    medium = 0.3
    setColorGrey(background, false)
    screen.drawRectF(0, 0, Swidth, Sheight)
    if isTransmit then
        setSignalColor(false)
    else
        setColorGrey(light, false)
    end
    screen.drawText(12, 26, "TRANSMIT")

    setColorGrey(medium, false)
    screen.drawLine(0, 24, 64, 24)

    --Signal strength as parralel bars with growing length 5 in total
    activeTo = math.round((sSelected == 1 and sStrength1 or sStrength2) * 5)
    ssBars = Vec2(2, 22)
    for i = 0, 4 do
        if i < activeTo then
            setColorGrey(0.3, false)
        else
            setSignalColor(false)
        end
        xOffset = i * 2
        height = i + 1
        barStart = addVec2(ssBars, Vec2(xOffset, 0))
        barEnd = addVec2(ssBars, Vec2(xOffset, -height))
        screen.drawLine(barStart.x, barStart.y, barEnd.x, barEnd.y)
    end

    setColorGrey(0.4, false)
    if sSelected == 1 then
        setSignalColor(false)
    end

    drawMatrixFromString(radioOneMatrixStr, 5, 5, 1, 5)

    setColorGrey(0.4, false)
    if sSelected == 2 then
        setSignalColor(false)
    end

    drawMatrixFromString(radioTwoMatrixStr, 5, 5, 8, 5)


end

--Matrix for the indicators of the selected radio
--# # # # #
--0 0 # 0 0
--0 0 # 0 0
--0 0 # 0 0
--# # # # #
--as string 1111100100001000010011111

--# # # # #
--0 # 0 # 0
--0 # 0 # 0
--0 # 0 # 0
--# # # # #
--as string 1111101010010100101011111