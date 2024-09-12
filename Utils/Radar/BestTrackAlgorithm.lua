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
---@param coordinate table<x, y, z> Coordinate of the first point
---@return Track Track new track object at the given coordinate
---@section Track
function Track(coordinate)
    return {
        coordinates = {coordinate}, --table of coordinates (3D space) ---@type table<table<x, y, z>>
        tSinceUpdate = 0, --time in ticks
        tickDeltas = {}, --table of time deltas between each update
        angle = 0, --in radians
        speed = 0, ---@type number Meters per tick
        calcAngle = function (self)
            angle = math.sin((self.coordinates[#self.coordinates].y - self.coordinates[#self.coordinates - 1].y) / distance2D(self.coordinates[#self.coordinates], self.coordinates[#self.coordinates - 1]))
        end,
        calcSpeed = function (self)
            speed = distance2D(self.coordinates[#self.coordinates], self.coordinates[#self.coordinates - 1]) / self.tSinceUpdate --m/tick
        end,
        tostring = function (self)
            return "c:" .. table.concat(self.coordinates[#self.coordinates], "|") .. " dt:" .. self.tSinceUpdate .. " a:" .. string.format("%03d", math.floor(math.deg(self.angle))) .. " s:" .. string.format("%02d", math.ceil(self.speed))
        end,
        getLatest = function (self)
            return self.coordinates[#self.coordinates]
        end,
        update = function (self)
            table.insert(self.tickDeltas, self.tSinceUpdate)
            self.tSinceUpdate = self.tSinceUpdate + 1
        end,
        calcEstimatePosition = function (self)
            return {
                x = self.coordinates[#self.coordinates].x + self.speed * math.cos(self.angle) * self.tSinceUpdate,
                y = self.coordinates[#self.coordinates].y + self.speed * math.sin(self.angle) * self.tSinceUpdate,
                z = self.coordinates[#self.coordinates].z
            }
        end
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
                bestTrack = tracks[bestTrackArray[i]]

                --update the track accordingly
                table.insert(bestTrack.coordinates, contacts[i])
                bestTrack.tSinceUpdate = 0
                bestTrack:calcAngle()
                bestTrack:calcSpeed()


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
    local matrix = {}
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