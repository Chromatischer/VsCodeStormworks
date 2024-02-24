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
    simulator:setScreen(1, "3x2")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(2, screenConnection.touchX)
        simulator:setInputNumber(3, screenConnection.touchY)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Utils.Utils")

anotherVariable = 900
textsToDisplay = {{x = 2, y = 2, string = "Fuel", variable = anotherVariable, format = 2}}

ticks = 0
function onTick()
    ticks = ticks + 1
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()
    screen.setColor(90,90,90)
    screen.drawRect(0,0,Swidth-1,Sheight-1)

    screen.setColor(240,115,10)
    for index, textField in ipairs(textsToDisplay) do
        screen.drawText(textField.x,textField.y,textField.string)
        textField.format = textField.format and textField.format or 1
        if textField.format == 1 then
            format = "%04d"
        elseif textField.format == 2 then
            format = "%03d"
        elseif textField.format == 3 then
            format = "%0.2f"
        else
            format = "%03d"
        end
        appendix = ""
        if textField.format == 2 then
            appendix = "%"
        elseif textField.format == 4 then
            appendix = "M"
        end
        screen.drawText(textField.x,textField.y + 7,string.format(format,math.floor(textField.variable)) .. appendix)
    end
end
