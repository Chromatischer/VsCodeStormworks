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
--#endregion

require("Utils.Fish")
require("Utils.VirtualMapUtils")
require("Utils.Color")
require("Utils.DrawAddons")
require("Utils.StringFormatUtils")

zoom = 5
zooms = { 0.1, 0.2, 0.5, 1, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50}
allFish = {} ---@type table<Fish>
virtualMap = nil ---@type VirtualMap
screenCenterX, screenCenterY = 0, 0
lastGlobalScale = 1
isUsingCHZoom = false
selfID = 0

ticks = 0
function onTick()
    ticks = ticks + 1
    CHGlobalScale = input.getNumber(1)
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

    if input.getBool(4) then
        fish = Fish(gpsX, gpsY, gpsZ, compas, (input.getNumber(12) * 360) + 180, input.getNumber(13), input.getNumber(14))
        table.insert(allFish, fish)
        for i = #allFish, 1, -1 do
            fish = allFish[i] ---@type Fish
            fish:update()
            if fish:isDead() then -- Oh no, the fish is dead!
                table.remove(allFish, i)
            end
        end
    end

    if isUsingCHZoom then
        zoom = math.clamp(CHGlobalScale, 1, 21)
    end
    if CHGlobalScale ~= lastGlobalScale then
        isUsingCHZoom = true
    end
    lastGlobalScale = CHGlobalScale

    --#region Setting values on Boot
    if ticks < 10 then
        screenCenterX, screenCenterY = gpsX, gpsY
        lastGlobalScale = CHGlobalScale
    end
    --#endregion
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    virtualMap = virtualMap(screenCenterX, screenCenterY, Swidth, Sheight, zooms[zoom], true)

    onScreenX, onScreenY = virtualMap:toScreenSpace(screenCenterX, screenCenterY, vesselAngle)
    drawDirectionIndicator(onScreenX, onScreenY, CHDarkmode, vesselAngle)

    for _, fish in ipairs(allFish) do
        fish = fish ---@type Fish
        fish:drawSpotToScreen(virtualMap, vesselAngle)
    end

    if not zoom == CHGlobalScale then
        setColorGrey(0.7, CHDarkmode)
        screen.drawText(2, 2, "D: " .. string.formatNumberAsInteger(zooms[zoom], 3, "0"))
    end
end