---@diagnostic disable: duplicate-doc-field

---Track object with coordinates, time since the last update, angle and speed
---@class Track Track object
---@field coordinates table<Vec3> table of coordinates (3D space)
---@field tSinceUpdate number Time since the last update in Ticks
---@field angle number Angle in radians
---@field speed number Meters per tick
---@field lastUpdateIndex number Index of coordinate of the last update
---@field getUpdatePos function Returns the last update position
---@field dataUpdate function Resets the time since the last update and sets the lastUpdateIndex to the last coordinate
---@param coordinate Vec3 Coordinate of the first point
---@return Track Track new track object at the given coordinate
---@section Track
function Track(coordinate)
    return {
        coordinates = {coordinate}, ---@type table<Vec3> table of coordinates (3D space) 
        tSinceUpdate = 0, ---@type number Time since the last update to the Track in ticks
        angle = 0, ---@type number Angle of travel in radians
        deltaAngle = 0, ---@type number 
        speed = 0, ---@type number Meters per tick
        updates = 0,
        lastUpdateIndex = 1,
    }
end
---@endsection

---Calculates the angle of the track in radians
---@class Track
---@field calcAngle function Calculate the angle of the track
---@param self Track Track object
---@section calcAngle
function calcAngle(self)
    self.angle = angleTo(vec3ToVec2(getLatest(self)), vec3ToVec2(getUpdatePos(self))) + math.pi / 2 --TODO: check if this works
end
---@endsection

---Calculates the speed of the track in m/tick
---@class Track
---@field calcSpeed function Calculate the speed of the track
---@param self Track Track object
---@section calcSpeed
function calcSpeed(self)
    --DONE: The speed is off by about a factor of 4
    --OMFG this cant be the problem... I forgor the self before the speed, so it was not updating the speed of the track but the speed of the function
    -- The problem is a division by 0. That means that tSinceUpdate has to be 0. Even if the distance is 0, the speed will be 0 not INF.
    self.speed = getDistanceSinceUpdate(self) / self.tSinceUpdate --m/tick
end
---@endsection

---Converts the Track object to a string
---@class Track
---@field trackToString function Convert the Track object to a string
---@param self Track Track object
---@return string String representation of the Track object
---@section trackToString
function trackToString(self)
    return "c:" .. table.concat(self.coordinates[#self.coordinates], "|") .. " dt:" .. self.tSinceUpdate .. " a:" .. string.format("%03d", math.floor(math.deg(self.angle))) .. " s:" .. string.format("%02d", math.ceil(self.speed))
end
---@endsection

---Returns the last coordinate that was saved to the Track
---@class Track
---@field getLatest function returns the latest vec3 coordinate object saved
---@param self Track Track object
---@return Vec3 Coordinate of the last point
---@section getLatest
function getLatest(self)
    return self.coordinates[#self.coordinates]
end
---@endsection

---Adds 1 tick to the tSinceUpdate variable
---@class Track
---@field update function
---@param self Track Track object
---@section update
function update(self)
    self.tSinceUpdate = self.tSinceUpdate + 1
end
---@endsection

---Calculates the estimated position of the track
---@class Track
---@field calcEstimatePosition function Calculates the estimated position of the track
---@param self Track Track object
---@return Vec2 Estimated position of the track at the current point of time
---@section calcEstimatePosition
function calcEstimatePosition(self)
    --What it acutally does: return (self.x * (self.speed * self.tSinceUpdate) * math.sin(rad))
    --This should be exactly what I need!
    return transformScalar(vec3ToVec2(getLatest(self)), self.angle, self.speed * self.tSinceUpdate) --This looks really nice tbh but I have to test it
end
---@endsection

---updates the internal Data
---@class Track
---@field dataUpdate function updates the internal Data
---@param self Track Track object
---@section dataUpdate
function dataUpdate(self)
    self.tSinceUpdate = 0
    self.lastUpdateIndex = #self.coordinates
end
---@endsection

---Returns the distance since the last update
---@class Track
---@field getDistanceSinceUpdate function Returns the distance since the last update
---@param self Track Track object
---@return number number the distance traveled since last updated
---@section getDistanceSinceUpdate
function getDistanceSinceUpdate(self)
    return distanceToVec3(getLatest(self), getUpdatePos(self))
end
---@endsection

function getUpdatePos(self)
    return self.coordinates[self.lastUpdateIndex]
end

---Tries to find the best tracks for a given number of contacts
---
---Time complexity: O(n^2) [use accordingly... try to avaoid unnessary calls]
---
---This malgorithm may not find the best solution. But the problability of finding a solution that is wrong, is very low. Because for one: two tracks and contact pairs have to be
---extremely close to each other and the order of the contacts is reverse of that of the tracks in storage. This will make the tracks update with contacts that dont belong to them.
---Imagine, having two planes flying in opposite directions and the contacts are mixed up. The order will swap and for a few ticks it will be wrong, but the algorithm will correct itself after a few updates.
---
---The algorithm works as follows:
---
---Iterate over the contacts in reverse order to remove contacts that have been assigned to a track
---
---For each contact, iterate over the tracks to find the best track for the current contact
---
---Check if the track has been used previously to avoid double assignment
---
---Calculate the distance between the contact and the track
---
---Assign the index of the best track to the bestTrackArray at the index of the current contact
---
---Check if a best track has been found for the current contact
---
---Check if the distance between the contact and the best track is less than the maximum distance
---
---Update the track accordingly
---
---Remove the contact from the contacts array as it has been assigned to a track
---@param contacts table<table<x, y, z>> Table of contacts
---@param tracks table<Track> Table of tracks
---@param maxDistance number Maximum distance between a contact and a track
---@return table<Track>, table<table<x, y, z>> Updated tracks and remaining contacts
---@section bestTrackAlgorithm
function bestTrackAlgorithm(contacts, tracks, maxDistance)
    --TODO: Maybe allow multi target assignment because of some errors experienced
    distanceArray = newMatrix(#contacts, #tracks, 0) --table<table<number>> Table of distances between each contact and each track
    usedTracks = {} --table<boolean> Table of used tracks
    bestTrackArray = {} --table<number> Table of the index of the best track for each contact

    for i = #contacts, 1, -1 do --iterate through the contact array in reverse order to remove contacts that have been assigned to a track
        minDistance = math.huge
        for j = 1, #tracks do --iterate through the track array to find the best track for the current contact
            if usedTracks[j] ~= true then --check if the track has been used previously to avoid double assignment
                dst = tracks[j]:getLatest():distanceTo(contacts[i]) --calculate the distance between the contact and the track (now with Vec3)
                distanceArray[i][j] = dst
                if dst < minDistance then
                    minDistance = dst
                    bestTrackArray[i] = j --assign the index of the best track to the bestTrackArray at the index of the current contact
                    usedTracks[j] = true -- Do not allow double assignment
                end
            end
            tracks[j].updates = 0
        end
        if bestTrackArray[i] ~= nil then --check if a best track has been found for the current contact
            if distanceArray[i][bestTrackArray[i]] < maxDistance then --check if the distance between the contact and the best track is less than the maximum distance
                bestTrack = tracks[bestTrackArray[i]] ---@class Track

                --update the track accordingly
                table.insert(bestTrack.coordinates, contacts[i])
                if bestTrack.tSinceUpdate ~= 0 then
                    bestTrack:calcAngle()
                    bestTrack:calcSpeed()
                end
                bestTrack.updates = bestTrack.updates + 1
                bestTrack:resetTimeSinceUpdate() --maybe this will solve the problem
                --bestTrack.tSinceUpdate = 1 -- This line influences the line before it... IDK why or how but it does

                --remove the contact from the contacts array as it has been assigned to a track
                table.remove(contacts, i)
            end
        end
    end
    return tracks, contacts --returns the updated tracks and the remaining contacts
end
---@endsection

---Assings multiple contacts to a single track but only one track to any single contact
---@param contacts table<Vec3> Table of contacts
---@param tracks table<Track> Table of tracks
---@param maxDistance number Maximum distance between a contact and a track
---@return table<Track> Tracks Updated tracks
---@return table<Vec3> Contacts Remaining contacts
---@section bestTrackDoubleAssignements
function bestTrackDoubleAssignements(contacts, tracks, maxDistance)
    -- Each contact should be assigned to only one track, but each track can have multiple contacts.
    -- This is achieved by iterating over tracks first, then contacts.
    -- Once a contact is assigned, it is removed from the contacts array, preventing multiple assignments.
    -- The algorithm calculates distances between tracks and contacts, assigns contacts to tracks if within maxDistance, and updates tracks.
    for i = 1, #tracks do
        track = tracks[i] ---@type Track
        isUpdated = false
        for j = #contacts, 1, -1 do
            contact = contacts[j] ---@type Vec3
            conditionAtPrevious = distanceToVec3(getLatest(track), contact) < maxDistance
            --Calculates the estimated position of the contact at the current time, converts to vec3 with z being latest recorded z
            --Checks if the distance between the contact and the best track is less than the maximum distance
            conditionAtPredicted = distanceToVec3(vec2ToVec3(calcEstimatePosition(track), getLatest(track).z), contact) < maxDistance
            if conditionAtPrevious or conditionAtPredicted then --check if the distance between the contact and the best track is less than the maximum distance
                table.insert(track.coordinates, contact)
                isUpdated = true
                table.remove(contacts, j) --remove the contact from the contacts array as it has been assigned to a track
            end
        end
        if isUpdated then
            calcAngle(track)
            calcSpeed(track)
            dataUpdate(track) --maybe this will solve the problem (it didn't but it doesn't hurt so I'll leve it as is)
        end
    end

    return tracks, contacts --returns the updated tracks and the remaining contacts
end
---@endsection

---Update the time since the last update of each track adding 1 tick
---@param tracks table<Track> Table of tracks
---@return table<Track> Tracks Updated tracks
---@section updateTrackT
function updateTrackT(tracks)
    for i = 1, #tracks do
        tracks[i].tSinceUpdate = tracks[i].tSinceUpdate + 1
    end
    return tracks
end
---@endsection

---Creates a new matrix with the given number of rows and columns and fills it with the given values
---@param rows number Number of rows
---@param cols number Number of columns
---@param val any Value to fill the matrix with
---@return table<table<any>> 2DMatrix new matrix filled with the given value
---@section newMatrix
function newMatrix(rows, cols, val)
    matrix = {}
    for i = 1, rows do
        matrix[i] = {}
        for j = 1, cols do
            matrix[i][j] = val
        end
    end
    return matrix
end
---@endsection

---Checks if two tables have equal content
---@param a table<any> Table A
---@param b table<any> Table B
---@return boolean Boolean true if the tables have the same content, false otherwise
---@section areTablesEqual
function areTablesEqual(a, b)
    return table.concat(a) == table.concat(b)
end
---@endsection