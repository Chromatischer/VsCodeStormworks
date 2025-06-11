-- Author: Chromatischer
-- GitHub: github.com/Chromatischer
-- Workshop: steamcommunity.com/profiles/76561199061545480/
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

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
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection

--#region CH Layout
-- N-1: Global Scale
-- N-2: GPS X
-- N-3: GPS Y
-- N-4: GPS Z
-- N-5: Vessel Angle
-- N-6: Screen Select I
-- N-7: Screen Select II
-- N-8: Touch X I
-- N-9: Touch Y I
-- N-10: Touch X II
-- N-11: Touch Y II

-- B-1: Global Darkmode
-- B-2: Touch I
-- B-3: Touch II
--#endregion

require("Vectors.Vectors")
require("Radar.BestTrackAlgorithm")
require("Radar.radarToGlobalCoordinates")


worldPos = Vec3(0, 0, 0) --TODO: Read in and remove this redundant declaration!

rawRadarData = {}
radarRotation = 0 ---@type number Radar rotation, normalized to rad
MAX_SEPERATION = 50 ---@type number
LIFESPAN = 20 ---@type number Lifespan till track deprecation in seconds
contacts = {} ---@type Vec3[]
tracks = {} ---@type Track[]

intercepts = {} --TODO: Maybe?

ticks = 0
function onTick()
    ticks = ticks + 1

    dataOffset = 11
    boolOffset = 5
    for i = 0, 3 do
        distance = input.getNumber(i * 4 + dataOffset)
        targetDetected = input.getBool(i + boolOffset)
        timeSinceDetected = input.getNumber(i * 4 + 3 + dataOffset)
        relPos = radarToRelativeVec3(distance, input.getNumber(i * 4 + 1 + dataOffset), input.getNumber(i * 4 + 2 + dataOffset), compas, input.getNumber(13))
        tgt = rawRadarData[i + 1]

        if timeSinceDetected ~= 0 then
            -- Using target smoothing like Smithy
            -- new = old + ((new - old) / n)
            rawRadarData[i + 1] = addVec3(tgt, scaleDivideVec3(subVec3(relPos, tgt), timeSinceDetected))

            -- Using recursive averaging
            -- new = ((old * n-1) + new) / n
            -- rawRadarData[i + 1] = tgt and scaleDivideVec3(addVec3(relPos, scaleVec3(tgt, timeSinceDetected - 1)), timeSinceDetected) or relPos
        elseif tgt then --Check that there is a contact at the postion.
            table.insert(contacts, addVec3(worldPos, tgt))
            rawRadarData[i + 1] = nil
        end
    end

    tracks = updateTrackT(tracks) ---@type Track[]

    if #contacts ~= 0 then -- Now possible through the use of the Hungarian algorithm
        -- This is the complete solution: updating, deleting and creating in one! Amazing
        tracks = hungarianTrackingAlgorithm(contacts, tracks, MAX_SEPERATION, LIFESPAN * 60, {})
        contacts = {} -- Clear contacts!
    end
end

function onDraw()
    --TODO: Draw that shit to the screen!
end
