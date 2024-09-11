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

require("Utils.Utils")
require("Utils.Radar.BestTrackAlgorithm")
require("Utils.Radar.radarToGlobalCoordinates")

--Will use 3 simultaneous contacts for now... so that means: 3 azimuths, 3 elevations, 3 distances, 3 contact statuses

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

lastRadarRotation = 0
lastRadarDelta = 0
radarMovingPositive = true
tracks = {} ---@type table<Track> Tracks
contacts = {} ---@type table<x, y, z> Contacts
selfID = 0
SelfIsSelected = false
reachedLimit = false

trackMaxUpdateTicks = 600
trackMaxGroupDistance = 100

ticks = 0
function onTick()
    ticks = ticks + 1
    CHGlobalScale = input.getNumber(1)
    gpsX = input.getNumber(2)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(4)
    compas = input.getNumber(5)
    CHSel1 = input.getNumber(6)
    CHSel2 = input.getNumber(7)
    touchX = CHSel1 == selfID and input.getNumber(8) or input.getNumber(10)
    touchY = CHSel1 == selfID and input.getNumber(9) or input.getNumber(11)
    radarRotation = (input.getNumber(12) * 360) % 360
    pitch = input.getNumber(13)


    CHDarkmode = input.getBool(1)
    monitorIsTouched = CHSel1 == selfID and input.getBool(2) or input.getBool(3)
    SelfIsSelected = CHSel1 == selfID or CHSel2 == selfID
    selfID = property.getNumber("Self ID: ")

    --Read the raw data into the Raw tables
    local dataOffset = 14
    local boolOffset = 4
    for i = 0, 2 do
        if input.getBool(i + boolOffset) then
            --adds the contacts to the contacts table in the form of x, y, z coordinates
            table.insert(contacts, radarToGlobalCoordinates(input.getNumber(i * 3 + dataOffset), input.getNumber(i * 3 + 1 + dataOffset), input.getNumber(i * 3 + 2 + dataOffset), gpsX, gpsY, gpsZ, compas, pitch))
        end
    end

    radarIsContinousRotation = property.getBool("Radar Mode: ")
    --Right now I will not do pre-target smoothing using the time since detected... I will use the plain position, but this will be an option in the future
    --This checks if either the radar has done a full rotation, or if the radar has changed direction, so has hit one of its limits and is now moving the other way
    if (radarRotation % 360 == 0 and radarIsContinousRotation) or (lastRadarDelta > 0 and radarMovingPositive or lastRadarDelta < 0 and not radarMovingPositive and not radarIsContinousRotation) then
        reachedLimit = true
        for i = #tracks, 1, -1 do --Step I: delete dead tracks
            if tracks[i].tSinceUpdate > trackMaxUpdateTicks then
                table.remove(tracks, i)
            end
        end

        tracks, contacts = bestTrackAlgorithm(contacts, tracks, trackMaxGroupDistance) --Step II: update tracks

        for i = #contacts, 1, -1 do --Step III: make new tracks from remaining contacts and remove them from the contacts table
            table.insert(tracks, Track(contacts[i]))
            table.remove(contacts, i)
        end
        assert(#contacts == 0, "CTable not empty D:")
    end
    --#region Radar movement direction
    lastRadarDelta = radarRotation - lastRadarRotation
    lastRadarRotation = radarRotation
    radarMovingPositive = lastRadarDelta > 0
    --#endregion



end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    screen.setColor(255, 255, 255)
    i = 0
    for _, track in ipairs(tracks) do
        screen.drawText(2, 2 + i * 7, "T: ", i, " X: ", numToFormattedInt(track:getLatest().x, 4), " Y: ", numToFormattedInt(track:getLatest().y, 4), " Z: ", numToFormattedInt(track:getLatest().z, 4))
        i = i + 1
    end
    screen.drawText(2, 26, "C: ", #contacts)
    screen.drawText(2, 33, "T: ", #tracks)
    screen.drawText(2, 40, "RR: ", radarRotation)
    screen.drawText(2, 47, "RM: ", radarMovingPositive)

    if reachedLimit then
        screen.setColor(255, 0, 0)
        screen.drawClear()
        reachedLimit = false
    end
end
