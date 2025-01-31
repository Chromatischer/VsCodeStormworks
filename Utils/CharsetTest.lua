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

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
    end;
end
---@endsection

require("Utils.Charset")

charset = nil ---@type Charset

ticks = 0
function onTick()
    ticks = ticks + 1
    if ticks < 10 then
        charset = Charset(62)
    end
end

function onDraw()
    screen.setColor(255, 255, 255)
    drawChar(charset, 1, 1, math.floor(ticks / 30) % 62)
    drawString(charset, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 1, 7)
    drawString(charset, "0123456789", 1, 13)
    drawString(charset, "$1 $2 $3 $4 $5 $10", 1, 19)
    drawString(charset, "$1$2$3$4$5$10", 1, 25)
    drawString(charset, "$10$12$13$14$15$17", 1, 31)
    drawString(charset, "HELLO EVERYONE", 1, 37)
    drawString(charset, "THIS IS MY NEWEST", 1, 43)
    drawString(charset, "PROJECT", 1, 49)

end
