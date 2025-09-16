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
    simulator:setScreen(1, "1x1")
    simulator:setProperty("Max Speed", 60)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, simulator:getSlider(1)*60)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require("Utils")
require("Circle_Draw_Utils")
require("draw_additions")


ticks = 0
currentSpeed = 0
function onTick()
    ticks = ticks + 1
    currentSpeed = currentSpeed * 0.95 + (input.getNumber(1) * 3.6) * 0.05
    maxSpeed = property.getNumber("Max Speed") * 3.6
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()
    IndicatorCenterX = Swidth/2
    IndicatorCenterY = Sheight/2
    IndicatorRadius = Sheight/2-1
    start = math.pi * 2
    indicatorRads = math.pi + math.pi * 1/2
    screen.setColor(255, 255, 255)
    --drawCircle(IndicatorCenterX, IndicatorCenterY, IndicatorRadius, 16, start, indicatorRads)
    drawSmallLinesAlongCircle(IndicatorCenterX, IndicatorCenterY, IndicatorRadius, 12, start, indicatorRads, 1)
    screen.setColor(255,255,255)
    drawSmallLinesAlongCircle(IndicatorCenterX, IndicatorCenterY, IndicatorRadius, 6, start, indicatorRads, 4)
    screen.drawLine(Swidth-4,Sheight/2,Swidth-1,Sheight/2)
    str = "KPH"
    screen.drawText(Swidth/2-(stringPixelLength(str)/2),Sheight/2-6,str)
    spdstr = currentSpeed > 0 and string.format("%03d",math.floor(currentSpeed)) or "STP"
    screen.drawText(16,20,spdstr)
    screen.setColor(255, 0, 0)
    drawIndicatorInCircle(IndicatorCenterX, IndicatorCenterY, start, indicatorRads, IndicatorRadius, currentSpeed, 0, maxSpeed)
end
