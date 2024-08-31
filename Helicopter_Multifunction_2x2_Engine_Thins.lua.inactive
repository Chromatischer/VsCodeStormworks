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
    simulator:setScreen(1, "2x2")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, 1 - simulator:getSlider(1) * 2)
        simulator:setInputNumber(2, 1 - simulator:getSlider(2) * 2)
        simulator:setInputNumber(3, 1 - simulator:getSlider(3) * 2)
    end;
end
---@endsection

require("Utils.Utils")
require("Utils.draw_additions")

ticks = 0
function onTick()
    ticks = ticks + 1
    yawInput = input.getNumber(1)
    pitchInput = input.getNumber(2)
    rollInput = input.getNumber(3)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    screen.setColor(255, 151, 35) -- Orange
    yawIndicatorCenterX = Swidth - 16
    yawIndicatorCenterY = Sheight - 16
    drawCircle(yawIndicatorCenterX, yawIndicatorCenterY, 10, 16, math.pi, math.pi)
    yawIndicatorPosition = yawInput * -math.piHalf

    screen.setColor(255, 139, 10)
    x1 = yawIndicatorCenterX + 8 * math.sin(yawIndicatorPosition)
    y1 = yawIndicatorCenterY + 8 * math.cos(yawIndicatorPosition)
    x2 = yawIndicatorCenterX + 12 * math.sin(yawIndicatorPosition)
    y2 = yawIndicatorCenterY + 12 * math.cos(yawIndicatorPosition)
    screen.drawLine(x1, y1, x2, y2)

    screen.setColor(35, 255, 41) -- Green
    pitchIndicatorCenterX = Swidth - 16
    pitchIndicatorCenterY = Sheight - 26
    pitchIndicatorLength = 16
    screen.drawLine(pitchIndicatorCenterX, pitchIndicatorCenterY, pitchIndicatorCenterX, pitchIndicatorCenterY + pitchIndicatorLength)
    screen.setColor(0, 139, 4)
    pitchIndicatorPosition = pitchIndicatorCenterY + pitchIndicatorLength / 2 + pitchInput * pitchIndicatorLength / 2
    screen.drawLine(pitchIndicatorCenterX - 2, pitchIndicatorPosition, pitchIndicatorCenterX + 2, pitchIndicatorPosition)

    screen.setColor(35, 139, 255) -- Blue
    rollIndicatorCenterX = Swidth - 16
    rollIndicatorCenterY = Sheight - 31
    rollIndicatorLength = 18
    screen.drawLine(rollIndicatorCenterX - rollIndicatorLength / 2, rollIndicatorCenterY, rollIndicatorCenterX + rollIndicatorLength / 2, rollIndicatorCenterY)

    screen.setColor(0, 90, 191)
    rollIndicatorPosition = rollIndicatorCenterX + rollInput * rollIndicatorLength / 2
    screen.drawLine(rollIndicatorPosition, rollIndicatorCenterY - 2, rollIndicatorPosition, rollIndicatorCenterY + 2)

    screen.setColor(255, 35, 249) -- Purple
    collectiveIndicatorCenterX = Swidth - 4
    collectiveIndicatorCenterY = Sheight - 31
    collectiveIndicatorLength = 26
    screen.drawLine(collectiveIndicatorCenterX, collectiveIndicatorCenterY, collectiveIndicatorCenterX, collectiveIndicatorCenterY + collectiveIndicatorLength)

    screen.setColor(113, 0, 202)
    collectiveIndicatorPosition = 
end
