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
    simulator:setScreen(2, "2x2")
    simulator:setScreen(3, "3x3")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(4, screenConnection.touchX)
        simulator:setInputNumber(5, screenConnection.touchY)
    end;
end
---@endsection

--#region Input Layout
-- Number Inputs:
-- 1: X
-- 2: Y
-- 3: Z
-- 4: Touch X
-- 5: Touch Y
-- 6: Distance

-- Bool Inputs:
-- 1: Active
-- 2: Pulse
-- 3: Touch
--#endregion

pulsePoints = {} -- table structure: {x, y, z, distance}
wasActive = false
intersections = {} -- table structure: {i1, i2, x, y}

-- Idea1: Pick at random two pulsePoints and calculate the intersection of their circles, save the intersection points in intersections table and go from there
--Pro: Less resource intensive then Idea3, Con: Uses older data with less accuracy, More difficult to implement
-- Idea2: Use only the latest two pulsePoints and calculate the intersection of their circles
--Pro: Less resource intensive then Idea3, Simple to implement, Uses the latest data with the highest accuracy
-- Idea3: Use all pulsePoints and calculate the intersection of all circles every tick
--Pro: Uses all data with the highest accuracy, Con: Most resource intensive

require("Utils.CircleIntersectionUtils")

ticks = 0
function onTick()
    ticks = ticks + 1

    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)

    touchX = input.getNumber(4)
    touchY = input.getNumber(5)

    tDistanceAnalog = input.getNumber(6)

    isActive = input.getBool(1)
    pulse = input.getBool(2)
    isDepressed = input.getBool(3)

    if isActive and not wasActive then
        pulsePoints = {}
    end
    wasActive = isActive

    if isActive and pulse then
        table.insert(pulsePoints, {gpsX, gpsY, gpsZ, tDistanceAnalog})
    end
end

function onDraw()
end