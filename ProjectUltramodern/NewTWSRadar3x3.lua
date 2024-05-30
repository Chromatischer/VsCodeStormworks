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


require("Utils.Utils")
require("Utils.Coordinate.Coordinate")
require("Utils.Coordinate.Coordinate_Utils")
require("Utils.TrackWhileScanUtils")


tempRadarData = {}
twsContacts = {}
twsBoxSize = 100
twsMaxUpdateTime = 300
twsMaxCoastTime = twsMaxUpdateTime * 5

ticks = 0
function onTick()
    ticks = ticks + 1
    --inputs
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(2)
    compas = input.getNumber(4)

    --NOTE: that everything that is iterated over needs to be iterated over back to front!

    for i = 0, 3 do -- calculating tempRadarData to use for the tws system
        radarDistance = input.getNumber(10 + i * 4)
        radarAzimuth = input.getNumber(11 + i * 4) * 360
        radarElevation = input.getNumber(12 + i * 4) * 360
        isRadarContact = input.getBool(4 + i * 4)

        if isRadarContact then
            radarRelativeCoordinate = newCoordinate(radarDistance * math.sin(math.rad(radarAzimuth)), radarDistance * math.cos(math.rad(radarAzimuth)), radarDistance * math.tan(math.rad(radarElevation)))
            tempRadarData[tempRadarData + 1] = {radarRelativeCoordinate}
        end
    end

    for index = #twsContacts, 1, -1 do
        twsContact = twsContacts[index]
        if twsContact then
            twsContact:addUpdateTime()
            for tempRadarIndex = #tempRadarContacts, 1, -1 do --Match every track to every temp contact check for box and then add to track and remove from temp storage
                tempRadarContact = tempRadarContacts[tempRadarIndex]
                twsLatestPosition = twsContact:getLatestHistoryPosition()
                if tempRadarContact:get3DDistanceTo(twsLatestPosition) < twsContact:getBoxSize() then
                    twsContact:addCoordinate(tempRadarContact)
                    table.remove(tempRadarContacts, tempRadarIndex)
                end
            end

            --if it is coasted use coast time if it is active or inactive then use update time
            if twsContact:getState() == 0 then
                if twsContact:getUpdateTime() > twsMaxUpdateTime then
                    twsContact:coast() --first coast
                end
            --Ok so in theory: only state 1 and 2 can get here! 1 is coasted so its checked against maxCoastTime 2 is inactive so its checked against maxUpdateTime!
            elseif (twsContact:getState() == 1 and twsContact:getUpdateTime() > twsMaxCoastTime) or (twsContact:getState() == 2  and twsContact:getUpdateTime() > twsMaxUpdateTime) then --should work :D
                    table.remove(twsContacts, index) --then delete
            end

            twsContact:predict()
        end
    end

    --add the new data if it is still left in the temp storage and deleting afterwards
    for tempRadarIndex = #tempRadarContacts, 1, -1 do
        tempContact = tempRadarContacts[tempRadarIndex]
        table.insert(twsContacts, newTrack(tempContact, twsBoxSize, twsMaxUpdateTime, twsMaxCoastTime, 3))
        table.remove(tempRadarContacts, tempRadarIndex)
    end
end

function onDraw()
    --TODO: Display data
end
