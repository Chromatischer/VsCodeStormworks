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
schools = {} ---@type table<table<globalX, globalX, color, size>>
virtualMap = nil ---@type VirtualMap
screenCenterX, screenCenterY = 0, 0
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
        for i = #allFish, 1, -1 do
            fish = allFish[i] ---@type Fish
            fish:update()
            if fish:isDead() then -- Oh no, the fish is dead!
                table.remove(allFish, i)
            end
        end

        --group the fishes into groups and add to the spots array, base the size on the amount of fishes in the "school"
        tempFishes = allFish ---@type table<Fish>

        --Idea: iterate over the full tempFishes array, then again, look for distances smaller then a pre-defined value, delete these fishes from the array, continue iterating
        for i = #tempFishes, 1, -1 do
            orderFish = tempFishes[i] ---@type Fish
            for o = #tempFishes, 1, -1 do
                questFish = tempFishes[o] ---@type Fish
                if orderFish and questFish then --check that the fish still exists and is not nil
                    if orderFish:getAsVec3():distanceTo(questFish:getAsVec3()) < 10 then --if the distance between the two fishes is smaller than 10m
                        schools[i] = {orderFish.globalX, orderFish.globalY, orderFish.color, schools[i] and schools[i][4] + 1 or 1} --add the fish to the school and increase the size by 1 if the school already exists
                        table.remove(tempFishes, o) --remove the fish from the tempFishes array
                    end
                end
            end
        end
    end

    --#region Setting values on Boot
    if ticks < 10 then
        screenCenterX, screenCenterY = gpsX, gpsY
    end
    --#endregion
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    virtualMap = VirtualMap(screenCenterX, screenCenterY, Swidth, Sheight, 100, false)

    onScreenX, onScreenY = virtualMap:toScreenSpace(screenCenterX, screenCenterY, vesselAngle)
    testPointNorthX, testPointNorthY = virtualMap:toScreenSpace(screenCenterX, screenCenterY + 10, vesselAngle)
    screen.drawLine(onScreenX, onScreenY, testPointNorthX, testPointNorthY)
    drawDirectionIndicator(onScreenX, onScreenY, CHDarkmode, 0)

    --for _, fish in ipairs(allFish) do
    --    if fish then -- Oh no, there is no fish!
    --        fish = fish ---@type Fish
    --        fish:drawSpotToScreen(virtualMap, vesselAngle)
    --    end
    --end

    for _, school in ipairs(schools) do
        if school then
            schX, schY = virtualMap:toScreenSpace(school[1], school[2], vesselAngle)
            color = school[3] ---@type Color
            size = school[4] * 3 ---@type number
            color:getWithModifiedValue(CHDarkmode and -0.3 or 0):setAsScreenColor()
            screen.drawCircleF(schX, schY, size)
            color:getWithModifiedValue(CHDarkmode and -0.5 or -0.2):setAsScreenColor()
            screen.drawCircle(schX, schY, size)

            setColorGrey(0.7, CHDarkmode)
            screen.drawText(schX - 1, schY - 1, size)
        end
    end

    setColorGrey(0.9, CHDarkmode)
    screen.drawText(1, 1, #allFish .. "F")
    screen.drawText(1, 8, #schools .. "S")

    setColorGrey(0.9, CHDarkmode)
end
