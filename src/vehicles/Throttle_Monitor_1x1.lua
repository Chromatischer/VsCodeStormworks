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
        simulator:setInputNumber(3,simulator:getSlider(1)*2-1)
        simulator:setProperty("Max Throttle Detent", 0.7)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Color_Lerp")
ticks = 0
currentThrottle = 0
maxThrottle = 1
minThrottle = -1
incFactor = 0.1
maxDetent = 0.7
lastThrottleMoveTicks = 0
function onTick()
    maxDetent = property.getNumber("Max Throttle Detent")
    ticks = ticks + 1
    incDecValue = input.getNumber(3) * incFactor
    if incDecValue > 0 then
        if currentThrottle + incDecValue < maxDetent or lastThrottleMoveTicks > 20 then
            if currentThrottle < 0 and currentThrottle + incDecValue < 0 or lastThrottleMoveTicks > 20 then
                currentThrottle = currentThrottle + incDecValue
            else
                currentThrottle = currentThrottle + incDecValue
            end
        end
    elseif incDecValue < 0 then
        if currentThrottle + incDecValue > -maxDetent or lastThrottleMoveTicks > 20 then
            if currentThrottle > 0 and currentThrottle + incDecValue > 0 or lastThrottleMoveTicks > 20 then
                currentThrottle = currentThrottle + incDecValue
            else
                currentThrottle = currentThrottle + incDecValue
            end
        end
    end

    currentThrottle = math.clamp(currentThrottle, -1, 1)

    if input.getNumber(3) > 0.1 or input.getNumber(3) < -0.1 then
        lastThrottleMoveTicks = 0
    else
        lastThrottleMoveTicks = lastThrottleMoveTicks + 1
    end
    output.setBool(1, currentThrottle < 0)
    output.setNumber(1, math.abs(currentThrottle))
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    screen.setColor(240, 115, 10)
    screen.setColor(90, 90, 90)
    screen.drawRect(0, 0, Swidth - 1, Sheight - 1)
    screen.drawLine(6, 0, 6, Sheight)

    absThrottle = math.abs(currentThrottle)
    for i = 0, absThrottle * (Sheight-2) do
        LerpedColor = colorLerp({r=255,g=0,b=0}, {r=0,g=255,b=0}, i/absThrottle)
        screen.setColor(LerpedColor.r, LerpedColor.g, LerpedColor.b)
        screen.drawLine(1, i * (Sheight-2), 5, i * (Sheight - 2))
    end
end
