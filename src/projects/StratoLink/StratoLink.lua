-- Author: Chromatischer
-- GitHub: github.com/Chromatischer
-- Workshop: steamcommunity.com/profiles/76561199061545480/
--
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

-- Project for a futuristic looking HUD for the new HUD-System for Helmet Mounted Displays!

ticks = 0
function onTick()
    ticks = ticks + 1
    pitch = input.getNumber(1)
    roll = input.getNumber(2)
    compas = input.getNumber(3) * 360 + 180 -- -0.5 to 0.5 to 0 to 360 Degrees

    altitude = input.getNumber(4)
    speed = input.getNumber(5)
    heading = input.getNumber(6)

    gpsX = input.getNumber(7)
    gpsY = input.getNumber(8)
    gpsZ = input.getNumber(9)

    lookX = input.getNumber(10)
    lookY = input.getNumber(11)

end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    screen.drawText(1, 1, "StratoLink HUD")
    screen.drawText(1, 7, "D: " .. Swidth .. "x" .. Sheight)
end
