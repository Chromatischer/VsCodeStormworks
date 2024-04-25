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
    simulator:setScreen(2, "2x1")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setProperty("Error Message 1", "Error 1")
        simulator:setProperty("Error Priority 1", 1)
        simulator:setProperty("Error Message 2", "Short")
        simulator:setProperty("Error Priority 2", 1)
        simulator:setProperty("Error Message 3", "Loooong Error!")
        simulator:setProperty("Error Priority 3", 2)
        simulator:setProperty("Error Message 4", "Fourth Error")
        simulator:setProperty("Error Priority 4", 3)
        simulator:setProperty("Error Message 5", "Dangerous Error")
        simulator:setProperty("Error Priority 5", 3)
        simulator:setProperty("Error Message 6", "very Dangerous")
        simulator:setProperty("Error Priority 6", 4)
        simulator:setProperty("Error Message 7", "Engine Overheat")
        simulator:setProperty("Error Priority 7", 2)
        simulator:setProperty("Error Message 8", "Low RPS")
        simulator:setProperty("Error Priority 8", 2)
        simulator:setProperty("Error Message 9", "High RPS")
        simulator:setProperty("Error Priority 9", 3)

        simulator:setInputBool(1, true)
        simulator:setInputBool(2, true)
        simulator:setInputBool(3, simulator:getIsClicked(3))
        simulator:setInputBool(4, true)
        simulator:setInputBool(5, simulator:getIsClicked(5))
        simulator:setInputBool(6, simulator:getIsClicked(6))
        simulator:setInputBool(7, simulator:getIsClicked(7))
        simulator:setInputBool(8, true)
        simulator:setInputBool(9, simulator:getIsClicked(9))

    end;
end
---@endsection

require("Utils.Utils")

errors = {}
maxLines = 0
lines = {"", "", "", ""}

ticks = 0
function onTick()
    ticks = ticks + 1
    lines = {"", "", "", ""}
    for i = 1, 9 do
        str1 = "Error Priority " .. i
        str2 = "Error Message " .. i
        priority = property.getNumber(str1)
        message = property.getText(str2)
        errors[i] = {s = message, p = priority}
        if input.getBool(i) then
            lines[priority] = lines[priority] .. message .. " "
        end
    end

end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()
    maxLines = math.floor((Sheight - 7) / 7)
    for iterator, text in pairs(lines) do
        if iterator == 1 then
            screen.setColor(0, 255, 0)
        elseif iterator == 2 then
            screen.setColor(100, 100, 100)
        elseif iterator == 3 then
            screen.setColor(255, 255, 0)
        elseif iterator == 4 then
            screen.setColor(255, 0, 0)
        end
        ything = 2 + iterator * 6
        if stringPixelLength(text) > Swidth then
            test = -((ticks / 50) % 5 * (stringPixelLength(text) / 5))
            screen.drawText(test, ything, text)
        else
            screen.drawText(0, ything, text)
        end
    end

    screen.setColor(255, 255, 255)
    topStr = Swidth > 32 and "Error Screen" or "Errors"
    screen.drawText(Swidth / 2 - stringPixelLength(topStr) / 2, 1, topStr)
end
