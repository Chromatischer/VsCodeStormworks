---Distance between point A and point B in 2D space
---@param coordinateA table<x, y> Coordinate A
---@param coordinateB table<x, y> Coordinate B
---@return number Distance between point A and point B
---@section distance2D
function distance2D(coordinateA, coordinateB)
    return math.sqrt((coordinateA.x - coordinateB.x)^2 + (coordinateA.y - coordinateB.y)^2)
end
---@endsection


---Distance between point A and point B in 3D space
---@param coordinateA table<x, y, z> Coordinate A
---@param coordinateB table<x, y, z> Coordinate B
---@return number Distance between point A and point B
---@section distance3D
function distance3D(coordinateA, coordinateB)
    return math.sqrt((coordinateA.x - coordinateB.x)^2 + (coordinateA.y - coordinateB.y)^2 + (coordinateA.z - coordinateB.z)^2)
end
---@endsection

---Track object with coordinates, time since the last update, angle and speed
---@class Track Track object
---@field coordinates [table<x, y, z>] table of coordinates (3D space)
---@field tSinceUpdate number Time since the last update in Ticks
---@field angle number Angle in radians
---@field speed number Meters per tick
---@field calcAngle function Calculate the angle of the track
---@field calcSpeed function Calculate the speed of the track
---@field getLatest function Get the latest coordinate of the track
---@field update function Add 1 tick to the tSinceUpdate variable
---@field calcEstimatePosition function Calculate the estimated position of the track
---@field getLatestDistance function Get the distance between the latest two coordinates of the track in 3D space
---@field getLatestDistance2D function Get the distance between the latest two coordinates of the track in 2D space
---@param coordinate table<x, y, z> Coordinate of the first point
---@return Track Track new track object at the given coordinate
---@section Track
function Track(coordinate)
    return {
        coordinates = {coordinate}, ---@type [table<x, y, z>] table of coordinates (3D space) 
        tSinceUpdate = 0, ---@type number Time since the last update to the Track in ticks
        angle = 0, ---@type number Angle of travel in radians
        speed = 0, ---@type number Meters per tick

        ---Calculates the angle of the track in radians
        ---@param self Track Track object
        calcAngle = function (self)
            self.angle = math.sin((self.coordinates[#self.coordinates].y - self.coordinates[#self.coordinates - 1].y) / self:getLatestDistance2D())
        end,

        ---Calculates the speed of the track in m/tick
        ---@param self Track Track object
        calcSpeed = function (self)
            --OMFG this cant be the problem... I forgor the self before the speed, so it was not updating the speed of the track but the speed of the function
            -- The problem is a division by 0. That means that tSinceUpdate has to be 0. Even if the distance is 0, the speed will be 0 not INF.
            if self.tSinceUpdate == 0 then
                self.speed = -9e4
            else
                self.speed = self:getLatestDistance() / self.tSinceUpdate --m/tick
            end
        end,

        --tostring = function (self)
        --    return "c:" .. table.concat(self.coordinates[#self.coordinates], "|") .. " dt:" .. self.tSinceUpdate .. " a:" .. string.format("%03d", math.floor(math.deg(self.angle))) .. " s:" .. string.format("%02d", math.ceil(self.speed))
        --end,

        ---Returns the last coordinate that was saved to the Track
        ---@param self Track Track object
        ---@return table<x, y, z> Coordinate of the last point
        getLatest = function (self)
            return self.coordinates[#self.coordinates]
        end,

        ---Adds 1 tick to the tSinceUpdate variable
        ---@param self Track Track object
        update = function (self)
            self.tSinceUpdate = self.tSinceUpdate + 1
        end,

        ---Calculates the estimated position of the track
        ---@param self Track Track object
        ---@return table<x, y, z> Estimated position of the track at the current point of time
        calcEstimatePosition = function (self)
            return {
                x = self.coordinates[#self.coordinates].x + self.speed * math.cos(self.angle) * self.tSinceUpdate,
                y = self.coordinates[#self.coordinates].y + self.speed * math.sin(self.angle) * self.tSinceUpdate,
                z = self.coordinates[#self.coordinates].z
            }
        end,

        ---Returns the distance between the latest two coordinates of the track in 3D space
        ---@param self Track Track object
        ---@return number Distance between the latest two coordinates of the track in 3D space
        getLatestDistance = function (self)
            return #self.coordinates > 1 and distance3D(self.coordinates[#self.coordinates - 1], self:getLatest()) or 0
        end,

        ---Returns the distance between the latest two coordinates of the track in 2D space
        ---@param self Track Track object
        ---@return number Distance between the latest two coordinates of the track in 2D space
        getLatestDistance2D = function (self)
            return #self.coordinates > 1 and distance2D(self.coordinates[#self.coordinates - 1], self:getLatest()) or 0
        end,

        --Commented out because it is only for debugging and will increase compile size
        --checkNil = function (self)
        --    return self:getLatest() == nil
        --end
    }
end
---@endsection

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
                dst = distance3D(contacts[i], tracks[j].coordinates[#tracks[j].coordinates]) --calculate the distance between the contact and the track
                distanceArray[i][j] = dst
                if dst < minDistance then
                    minDistance = dst
                    bestTrackArray[i] = j --assign the index of the best track to the bestTrackArray at the index of the current contact
                end
            end
        end
        if bestTrackArray[i] ~= nil then --check if a best track has been found for the current contact
            if distanceArray[i][bestTrackArray[i]] < maxDistance then --check if the distance between the contact and the best track is less than the maximum distance
                bestTrack = tracks[bestTrackArray[i]] ---@class Track

                --update the track accordingly
                table.insert(bestTrack.coordinates, contacts[i])
                bestTrack:calcAngle()
                bestTrack:calcSpeed()
                bestTrack.tSinceUpdate = 0 -- fuck this error

                --remove the contact from the contacts array as it has been assigned to a track
                table.remove(contacts, i)
            end
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

---@section Tests
--#region distance2D
assert(distance2D({x = 0, y = 0}, {x = 0, y = 0}) == 0, "distance2D test 1 failed")
assert(distance2D({x = 0, y = 0}, {x = 1, y = 0}) == 1, "distance2D test 2 failed")
assert(distance2D({x = 0, y = 0}, {x = 0, y = 1}) == 1, "distance2D test 3 failed")
assert(distance2D({x = 0, y = 0}, {x = 1, y = 1}) == math.sqrt(2), "distance2D test 4 failed")
print("Passed distacne 2D tests!")
--#endregion

--#region distance3D
assert(distance3D({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}) == 0, "distance3D test 1 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 1, y = 0, z = 0}) == 1, "distance3D test 2 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 0, y = 1, z = 0}) == 1, "distance3D test 3 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 1}) == 1, "distance3D test 4 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 1, y = 1, z = 1}) == math.sqrt(3), "distance3D test 5 failed")
print("Passed distacne 3D tests!")
--#endregion

--#region newTrack
track = Track({x = 0, y = 0, z = 0})
assert(track.coordinates[1].x == 0 and track.coordinates[1].y == 0 and track.coordinates[1].z == 0, "newTrack test 1 failed")
assert(track.tSinceUpdate == 0, "newTrack test 2 failed")
assert(track.angle == 0, "newTrack test 3 failed")
assert(track.speed == 0, "newTrack test 4 failed")
print("Passed newTrack tests!")
--#endregion

--#region bestTrackAlgorithm
contacts = {{x = 0, y = 0, z = 0}, {x = 1, y = 1, z = 1}, {x = 2, y = 2, z = 2}}
tracks = {Track({x = 0, y = 0, z = 0}), Track({x = 1, y = 1, z = 1})}
updateTrackT(tracks)
maxDistance = math.sqrt(2)
tracks, contacts = bestTrackAlgorithm(contacts, tracks, maxDistance)
assert(areTablesEqual(tracks[1].coordinates[#tracks[1].coordinates], {x = 0, y = 0, z = 0}), "bestTrackAlgorithm test 1 failed")
assert(areTablesEqual(tracks[2].coordinates[#tracks[2].coordinates], {x = 1, y = 1, z = 1}), "bestTrackAlgorithm test 2 failed")
assert(#contacts == 1, "bestTrackAlgorithm test 3 failed")
print("Passed bestTrackAlgorithm tests!")
--#endregion

--#region updateTrackT
tracks = {Track({x = 0, y = 0, z = 0}), Track({x = 1, y = 1, z = 1})}
tracks = updateTrackT(tracks)
assert(tracks[1].tSinceUpdate == 1, "updateTrackT test 1 failed")
assert(tracks[2].tSinceUpdate == 1, "updateTrackT test 2 failed")
print("Passed updateTrackT tests!")
--#endregion

--#region newMatrix
matrix = newMatrix(2, 2, 0)
assert(matrix[1][1] == 0 and matrix[1][2] == 0 and matrix[2][1] == 0 and matrix[2][2] == 0, "newMatrix test 1 failed")
print("Passed newMatrix tests!")
--#endregion

--#region areTablesEqual
assert(areTablesEqual({1, 2, 3}, {1, 2, 3}), "areTablesEqual test 1 failed")
assert(not areTablesEqual({1, 2, 3}, {1, 2, 4}), "areTablesEqual test 2 failed")
print("Passed areTablesEqual tests!")
--#endregion
---@endsection