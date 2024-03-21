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
    simulator:setScreen(1, "2x1")
    simulator:setProperty("Max Gear", 14)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(1, simulator:getSlider(1) * 14)
        simulator:setInputNumber(2, simulator:getSlider(2) * 500)
        simulator:setInputNumber(3, 500)
        simulator:setInputNumber(4, simulator:getSlider(3) * 100)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require("Utils.Utils")
require("Utils.Circle_Draw_Utils")
require("Utils.draw_additions")

ticks = 0
function onTick()
    ticks = ticks + 1
    currentGear = input.getNumber(1)
    maxGear = property.getNumber(1, "max Gear")
    isUpshift = getCommaPlaces(currentGear) > 0.5
    fuelLevel = input.getNumber(2)
    fuelCapacity = input.getNumber(3)
    fuelPercentage = fuelLevel / fuelCapacity

    engineTemp = input.getNumber(4)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    screen.setColor(255, 255, 255)
    shiftStr = isUpshift and "U" or ""
    gearString = string.format("%02d", math.floor(currentGear)) .. shiftStr
    screen.drawText(Swidth / 2 - stringPixelLength(gearString) / 2, 2, gearString)

    totalLength = 20
    screen.drawText(2, Sheight - 6, "T")
    screen.drawLine(2, 3 + (engineTemp / 100) * totalLength, 7, 3 + (engineTemp / 100) * totalLength)
    screen.drawLine(2, 3 + totalLength / 2, 4, 3 + totalLength / 2)
    screen.setColor(255, 0, 0)
    screen.drawLine(2, Sheight - 8, 6, Sheight - 8)
    screen.setColor(0, 100, 255)
    screen.drawLine(2, 2, 6, 2)
    screen.setColor(255, 255, 255)

    
end
