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
        simulator:setInputBool(1, simulator:getIsClicked(1))
        simulator:setInputBool(2, simulator:getIsClicked(2))
    end;
end
---@endsection


require("Utils")
require("Color_Lerp")

sticky_axis = 0
inc = 0.01
upper_lim = 1
lower_lim = -1
last_up = false
last_down = false
function onTick()
    up = input.getBool(1)
    down = input.getBool(2)

    if up then
        if (sticky_axis < 0 and sticky_axis + inc >= 0) then -- if sticky_axis is negative and incrementing will make it positive (moving across 0)
            if last_up ~= up then --if the last input was not up
               increment(inc)
            end
        else -- if sticky_axis is positive or incrementing will keep it negative
            increment(inc)
        end
    elseif down then
        if (sticky_axis > 0 and sticky_axis - inc <= 0) then -- if sticky_axis is positive and incrementing will make it negative (moving across 0)
            if last_down ~= down then --if the last input was not down
               decrement(inc)
            end
        else -- if sticky_axis is negative or incrementing will keep it positive
            decrement(inc)
        end
    end
    last_up = up
    last_down = down
    sticky_axis = math.clamp(sticky_axis, -1, 1)
    output.setNumber(1, sticky_axis)
end

function onDraw()
    for i = 1, 16 * math.abs(sticky_axis) do
        color = colorLerp({r = 0, g = 255, b = 0}, {r = 255, g = 0, b = 0}, i / 16)
        screen.setColor(color.r, color.g, color.b)
        screen.drawLine(0, 16 - (i * sign(sticky_axis)), 32, 16 - (i * sign(sticky_axis)))
    end
    screen.setColor(0, 0, 0)
    screen.drawRectF(2, 4, 28, 24)
    screen.setColor(150, 150, 150)
    screen.drawTextBox(0, 0, 32, 32, string.format("%03d", math.round(sticky_axis * 100)) .. "%", 0, 0)
end

function increment(amount)
    if sticky_axis + amount < upper_lim then
        sticky_axis = sticky_axis + amount
    else
        sticky_axis = upper_lim
    end
end

function decrement(amount)
    if sticky_axis - amount > lower_lim then
        sticky_axis = sticky_axis - amount
    else
        sticky_axis = lower_lim
    end
end