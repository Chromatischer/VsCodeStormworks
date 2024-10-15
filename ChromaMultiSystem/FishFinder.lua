-- Author: Chromatischer
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
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

--#region CH Layout
-- CH1: Global Scale
-- CH2: GPS X
-- CH3: GPS Y
-- CH4: GPS Z
-- CH5: Vessel Angle
-- CH6: Screen Select I
-- CH7: Screen Select II
-- CH8: Touch X I
-- CH9: Touch Y I
-- CH10: Touch X II
-- CH11: Touch Y II

-- CHB1: Global Darkmode
-- CHB2: Touch I
-- CHB3: Touch II
--#endregion

--#region Fish Finder Layout
-- CH12: Local Relative Yaw to Fish in turns
-- CH13: Local Relative Distance to Fish in meters (max distance 100m)
-- CH14: Local Relative Depth to Fish in meters

--CHB4: Fish Finder Active
--CHB5: Fish Detected
--#endregion

require("Utils.Fish")
require("Utils.VirtualMapUtils")
require("Utils.Color")
require("Utils.DrawAddons")
require("Utils.StringFormatUtils")
require("Utils.Utils")
require("Utils.Vectors.vec3")
require("Utils.Vectors.vec2")

allFish = {} ---@type table<Fish>
schools = {} ---@type table<table<Vec2, number, Color, number>>
virtualMap = nil ---@type VirtualMap
screenCenter = Vec2(0, 0)
selfID = 0

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(2)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(4)
    compas = input.getNumber(5)
    vesselAngle = (compas * 360) + 180
    CHSel1 = input.getNumber(6)
    CHSel2 = input.getNumber(7)
    touchX = CHSel1 == selfID and input.getNumber(8) or input.getNumber(10)
    touchY = CHSel1 == selfID and input.getNumber(9) or input.getNumber(11)

    CHDarkmode = input.getBool(1)
    isDepressed = CHSel1 == selfID and input.getBool(2) or input.getBool(3)
    SelfIsSelected = CHSel1 == selfID or CHSel2 == selfID
    selfID = property.getNumber("SelfID")

    if input.getBool(5) then --check that there is a fish detected you fucking twat
        fish = Fish(gpsX, gpsY, gpsZ, compas, (input.getNumber(12) * 360) + 180, input.getNumber(13), input.getNumber(14))
        table.insert(allFish, fish)
    end

    for i = #allFish, 1, -1 do
        allFish[i] = updateFish(allFish[i])
        if isDead(allFish[i]) then
            table.remove(allFish, i)
        end
    end

    screenCenter = Vec2(gpsX, gpsY)
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    virtualMap = VirtualMap(screenCenter.x, screenCenter.y, Swidth, Sheight, 200, false)

    onScreen = toScreenSpace(virtualMap, screenCenter, vesselAngle)
    testPoint = toScreenSpace(virtualMap, addY(screenCenter, 10), vesselAngle)
    screen.setColor(255, 255, 255)
    screen.drawLine(onScreen.x, onScreen.y, testPoint.x, testPoint.y)
    drawDirectionIndicator(onScreen.x, onScreen.y, CHDarkmode, 0)

    for _, fish in ipairs(allFish) do
        fishPos = toScreenSpace(virtualMap, vec3ToVec2(getAsVec3(fish)), vesselAngle)
        drawSpotToScreen(fish, virtualMap, vesselAngle, CHDarkmode)
        setColorGrey(0.9, CHDarkmode)
        screen.drawText(fishPos.x, fishPos.y, fish.age)
    end

    setColorGrey(0.9, CHDarkmode)
    screen.drawText(1, 1, #allFish .. "F")
    screen.drawText(1, 8, #schools .. "S")

    setColorGrey(0.9, CHDarkmode)
end
