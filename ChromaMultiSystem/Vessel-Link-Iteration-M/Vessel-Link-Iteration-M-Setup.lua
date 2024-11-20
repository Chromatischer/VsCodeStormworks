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
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)
    end;
end
---@endsection

require("Utils.RockerNumber")
require("Utils.Color")
require("Utils.DrawAddons")

selCode = 0
MAX_CODE = 198
hsvColor = convertToHsv(Color(255, 255, 255))
codeSelected = false

rockers = {createRockerNumber(0, 1, 0, 10, 30, hsvColor), createRockerNumber(0, 9, 0, 16, 30, hsvColor), createRockerNumber(0, 9, 0, 24, 30, hsvColor)}
okButton = {x = 30, y = 30, text = "OK"}

ticks = 0
function onTick()
    ticks = ticks + 1
    selCode = rockers[1].value * 100 + rockers[2].value * 10 + rockers[3].value
    if selCode > MAX_CODE then
        selCode = MAX_CODE
    end

    updateRockerNumbers(rockers, input.getNumber(1), input.getNumber(2), input.getBool(1))

    if isPointInRectangle(okButton.x, okButton.y, 10, 10, input.getNumber(1), input.getNumber(2)) then
        codeSelected = true
    end

    output.setNumber(1, codeSelected and selCode or -1)
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    screen.setColor(0, 0, 0)
    screen.drawRect(1, 1, Swidth, Sheight)
    screen.setColor(255, 255, 255)
    screen.drawTextBox(1, 1, Swidth, Sheight / 2, "Select Code: " .. string.format("03d", selCode), 0, 0)
    for i, rocker in ipairs(rockers) do
        rocker.color = hsvColor
        drawRockerNumber(rocker)
    end
    screen.drawText(okButton.x, okButton.y, okButton.text)
end
