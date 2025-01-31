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
        simulator:setInputNumber(2, screenConnection.touchX)
        simulator:setInputNumber(3, screenConnection.touchY)
    end;
end
---@endsection


require("Utils.Utils")
require("Utils.Coordinate.Coordinate")
require("Utils.Coordinate.Coordinate_Utils")
require("Utils.Radar.radarToGlobalCoordinates")
require("Utils.Radar.TrackWhileScanUtils")
require("Utils.Radar.HungarianAlgorithm")

globalScreenScale = 3
globalScreenScales = {100, 250, 500, 750, 1000, 1250, 1500, 2000, 2500, 3000, 4000, 5000, 7500, 10000, 15000, 20000}
inRadarData = {}
tempRadarData = {}
twsTracks = {}
twsBoxSize = 100
twsMaxUpdateTime = 300
twsMaxCoastTime = twsMaxUpdateTime * 5
twsActivationNumber = 2
deltaRotation = 0
lastRotation = 0
lastDeltaRotation = 0
minRadDistance = 90

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(13)
    gpsY = input.getNumber(15)
    gpsZ = input.getNumber(14)
    compas = input.getNumber(16)
    pitch = input.getNumber(17)
    radarRotation = input.getNumber(18)

    for i = 0, 3 do
        if input.getBool(i + 1) then
            inRadDistance = input.getNumber(1 + i * 3)  -- 1, 4, 7, 10
            inRadAzimuth = input.getNumber(2 + i * 3)   -- 2, 5, 8, 11
            inRadElevation = input.getNumber(3 + i * 3) -- 3, 6, 9, 12
            if inRadDistance > minRadDistance then --To not detect own subgrids
                inRadPosition = convertToCoordinateObj(radarToGlobalCoordinates(inRadDistance, inRadAzimuth, inRadElevation, gpsX, gpsY, gpsZ, compas, pitch))
                table.insert(inRadarData, inRadPosition) --Inserting only if there is a detection on the channel and the distance requirement is met
            end
        end
    end

    --#region Radar Rotation Deltas
    deltaRotation = radarRotation - lastRotation
    lastRotation = radarRotation
    --#endregion

    --#region pushing input data to the tws system
    --sign(x) will return -1 if x is negative, 0 if x is 0, and 1 if x is positive
    --that means that if the sign of the delta rotation is the same as the sign of the last delta rotation then we can assume that the radar is still rotating
    --if the sign of the delta rotation is different from the sign of the last delta rotation then we can assume that the radar has chaned direction
    --and we can flush to the tempRadarData and start processing the data
    --or if the rotation is 180 or 360 degrees if it is contiously rotating
    if (sign(deltaRotation) - sign(lastDeltaRotation) == 0) or (radarRotation % 180 == 0 and radarRotation ~= 0) then
        tempRadarData = {} --resetting the tempRadarData
        for i = 1, #inRadarData do
            table.insert(tempRadarData, inRadarData[i]) --moving all the data from the inRadarData to the tempRadarData
        end
        inRadarData = {} --resetting the inRadarData
    end
    lastDeltaRotation = deltaRotation --setting the last delta rotation to the current delta rotation
    --#endregion


    --IMPORTANT: tempData is rows and twsTracks are columns
    
    --creating the empty hungarian matrix to fill afterwards with the distances between the tempRadarData and the twsTracks
    hungarianMatrix = {}
    for i = 1, #tempRadarData do
        hungarianMatrix[i] = vec(#twsTracks) --creates a table with #tempRadarData rows and #twsTracks columns
    end

    --TODO: There can be problems with this because the algorithm only works if there are more rows then cols (I think this may not be true!)
    --TODO: Therefore creating dummy rows or cols will fix this issue!

    --Filling the hungarian matrix with the distances between the tempRadarData and the twsTracks
    for tempDex, tempCoordinate in pairs(tempRadarData) do
        for trackDex, twsCoordinate in pairs(twsTracks) do
            hungarianMatrix[trackDex + 1][tempDex + 1] = math.abs(tempCoordinate:get3DDistanceTo(twsCoordinate))
        end
    end

    if #hungarianMatrix > 0 and #hungarianMatrix[1] > 0 then
        normalizeTable(hungarianMatrix) --normalizing because there can either be more tracks or contacts
        bestDistances = hungarianAlgorithm(hungarianMatrix)

        --#region Update tracks using the hungarian matrix
        --updating the tracks and deleting the corresponding temp data
        for row, _ in pairs(bestDistances) do
            if hungarianMatrix[row][bestDistances[row]] ~= 9e2 then
                twsTracks[bestDistances[row]]:addCoordinate(tempRadarData[row]) --idk maybe?
            end
            --print("row: " .. row + 1 .. " col: " .. hungarianRes[row + 1] .. " val: " .. (referenceTable[row + 1][hungarianRes[row + 1]] == 9e2 and "H" or referenceTable[row + 1][hungarianRes[row + 1]]))
        end
        --#endregion
    end
    

    for i = #twsTracks, 1, -1 do
        track = twsTracks[i]
        track:addUpdateTime()
        --#region Delete and coast tracks that have not received updates
        if track:getState() == 1 then
            if track:getUpdateTime() > twsMaxCoastTime then
                track:coast()
            end
        else
            if track:getUpdateTime() > twsMaxUpdateTime then
                table.remove(twsTracks, i)
            end
        end
        --#endregion
        track:predict()
    end

    --#region Adding new tracks using the left over tempRadarData
    for i = #tempRadarData, 1, -1 do
        temp = tempRadarData[i]
        if temp ~= nil then
            table.insert(twsTracks, newTrack(temp, twsBoxSize, twsMaxUpdateTime, twsMaxCoastTime, twsActivationNumber))
        end
        table.remove(tempRadarData, i)
    end
    --#endregion
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    for _, track in ipairs(twsTracks) do
        onScreenX, onScreenY = toOnScreenPosition(track:getLatestHistoryPosition():getX(), track:getLatestHistoryPosition():getY())
        --switch colors based on track state
        if track:getState() == 0 then
            screen.setColor(255, 0, 0)
        elseif track:getState() == 1 then
            screen.setColor(0, 255, 0)
        end
        screen.drawRectF(onScreenX, onScreenY, 2, 2)

        n = 3 -- starting with length of 3
        for i = #track:getHistory(), #track:getHistory() - 3, -1 do
            currHistoryPos = track:getHistory()[i]
            if not currHistoryPos then
                goto continue
            end
            historyX, historyY = toOnScreenPosition(currHistoryPos:getX(), currHistoryPos:getY())
            firstX, firstY = historyX + n * math.sin(math.rad(compas)), historyY - n * math.cos(math.rad(compas))
            secondX, secondY = historyX + n * math.sin(math.rad(180 - compas)), historyY - n * math.cos(math.rad(180 - compas))
            screen.drawLine(firstX, firstY, secondX, secondY)
            ::continue::
            n = n - 1
        end

        --Draw UI
        screen.drawText(1, 1, globalScreenScales[globalScreenScale])
        screen.drawText(1, 5, #twsTracks .. " " .. #tempRadarData .. " " .. (radarRotation * 360))
    end

    for _, position in ipairs(tempRadarData) do --drawing the tempRadarData too because for debugging purposes it could be useful
        onScreenX, onScreenY = toOnScreenPosition(position:getX(), position:getY())
        screen.setColor(100, 100, 100, 100)
        screen.drawText(onScreenX, onScreenY, _) --drawing the number instead of a rect because!
    end
end

---converts a global coordinate into screen space and rotates it so that the compas angle is up on the map
---@param globalX number the global X coordinate
---@param globalY number the global Y coordinate
---@return number X the on Screen X position of the global coordinate
---@return number Y the on Screen Y position of the global coordinate
function toOnScreenPosition(globalX, globalY)
    local radAng = math.rad(compas)
    local screenSpaceX = gpsX - globalX / globalScreenScales[globalScreenScale] --converting from global to local e.g: 500m if the scale is 500 then the screenSpaceX will be 1 if the scale is 1000 then its 0.5
    local screenSpaceY = gpsY - globalY / globalScreenScales[globalScreenScale]
    local withAngleX = screenSpaceX * math.cos(radAng) - screenSpaceY * math.sin(radAng)
    local withAngleY = screenSpaceY * math.cos(radAng) + screenSpaceX * math.sin(radAng)
    return withAngleX, withAngleY
end