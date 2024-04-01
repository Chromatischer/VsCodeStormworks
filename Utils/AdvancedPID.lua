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
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!


-- ADVANCED PID CONTROLLER BY GAVIN DISTASO (Potoo)
---- code inspired by https://www.reddit.com/r/Stormworks/comments/kei6pg/lua_code_for_a_basic_pid/
---- HOW TO USE:
---- * set 'kp', 'ki', 'kd', and 'bias' below
-- * if you're having an integral windup issue set 'antiWindup' to true
-- * set min and max values for your output (this is necessary for anti-windup to work)
-- * composite number input 1 is setpoint *
-- * composite number input 2 is variable *
-- * composite number output 1 is PID out *
-- I recommend using 'NJ PID TUNER' if you don't know how to get P, I, and D values
-- 'NJ PID TUNER' can be found here: https://steamcommunity.com/sharedfiles/filedetails/?id=2354403971
-- EDIT THIS --
local kp = 0
local ki = 0
local kd = 0
local bias = 0
local antiWindup = true
local minOutput = -1
local maxOutput = 1
-- internal use only --
local errorPrior = 0
local integralPrior = 0
local antiWindupClamp = false
function onTick()
    setpoint = input.getNumber(1)
    variable = input.getNumber(2)
    --	
    error = setpoint - variable
    derivative = error - errorPrior
    --	
    if (not antiWindup or not antiWindupClamp) then
        integral = integralPrior + error
    elseif (antiWindupClamp) then
        integral = 0
    end
    --	
    out = kp * error + ki * integral + kd * derivative + bias
    clampedOut = math.max(math.min(out, maxOutput), minOutput)
    --	
    output.setNumber(1, clampedOut)
    --	
    -- * if you want to understand what anti-windup is and how this anti-windup works go here:	-- * https://www.mathworks.com/videos/understanding-pid-control-part-2-expanding-beyond-a-simple-integral-1528310418260.html	
    antiWindupClamp = (out ~= clampedOut) and (sign(error) == sign(out))
    --		
    errorPrior = error
    integralPrior = integral
end

function sign(x)
    if (x > 0) then
        return 1
    elseif (x == 0) then
        return 0
    else
        return -1
    end
end
