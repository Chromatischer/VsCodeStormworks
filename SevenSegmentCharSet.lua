-- Author: Chromatischer
-- GitHub: github.com/Chromatischer
-- Workshop: steamcommunity.com/profiles/76561199061545480/
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
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
        local screenConnection = simulator:getTouchScreen(1)
    end;
end
---@endsection



--Input 0 - 9 -> Numbers 0 - 9
--Input 10 -> A, B, C, D, E, F, G, H, J, L, N, P, R, U, Y
--Input 11 -> Space
--Input 12 -> Minus

--0 => 126
--1 => 48
--2 => 109
--3 => 121
--4 => 51
--5 => 91
--6 => 95
--7 => 112
--8 => 127
--9 => 123

chars = {126, 48, 109, 121, 51, 91, 95, 112, 127, 123}

ticks = 0
function onTick()
    output.setNumber(1, chars[input.getNumber(1) + 1])
end