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
---@section newTrack
function Track(coordinate)
    return {
        coordinates = {coordinate}, --table of coordinates (3D space) ---@type table<table<x, y, z>>
        tSinceUpdate = 0, --time in ticks
        angle = 0, --in radians
        speed = 0, --in m/s
        calcAngle = function (self)
            angle = math.sin((self.coordinates[#self.coordinates].y - self.coordinates[#self.coordinates - 1].y) / distance2D(self.coordinates[#self.coordinates], self.coordinates[#self.coordinates - 1]))
        end,
        calcSpeed = function (self)
            speed = distance2D(self.coordinates[#self.coordinates], self.coordinates[#self.coordinates - 1]) / (self.tSinceUpdate / 60) --speed in m/s
        end,
        tostring = function (self)
            return "c:" .. table.concat(self.coordinates[#self.coordinates], "|") .. " dt:" .. self.tSinceUpdate .. " a:" .. string.format("%03d", math.floor(math.deg(self.angle))) .. " s:" .. string.format("%02d", math.ceil(self.speed))
        end
    }
end
---@endsection

---Tries to find the best tracks for a given number of contacts
---@param contacts table<table<x, y, z>> Table of contacts
---@param tracks table<Track> Table of tracks
---@param maxDistance number Maximum distance between a contact and a track
---@return table<Track>, table<table<x, y, z>> Updated tracks and remaining contacts
---@section bestTrackAlgorithm
function bestTrackAlgorithm(contacts, tracks, maxDistance)
    --#region calculate the distance between each contact and each track and find the best track for each contact based on the minimum distance
    distanceArray = newMatrix(#contacts, #tracks, 0) --table<table<number>> Table of distances between each contact and each track
    bestMinDistanceTrack = {} --table<number> Table of the index of the best track for each contact
    for i = 1, #contacts do
        minDistance = math.huge
        for j = 1, #tracks do
            distanceArray[i][j] = distance3D(contacts[i], tracks[j].coordinates[#tracks[j].coordinates])
            if distanceArray[i][j] < minDistance then
                minDistance = distanceArray[i][j]
                bestMinDistanceTrack[i] = j
            end
        end
    end
    --#endregion

    --#region update the tracks with the best contact
    for i = #contacts, 1, -1 do
        bestTrack = tracks[bestMinDistanceTrack[i]] ---@type Track
        if distanceArray[i][bestMinDistanceTrack[i]] <= maxDistance and bestTrack.tSinceUpdate ~= 0 then --checks for the min distance requirement and if the track has been updated previously
            table.insert(bestTrack.coordinates, contacts[i])
            bestTrack.tSinceUpdate = 0
            bestTrack:calcAngle()
            bestTrack:calcSpeed()
            table.remove(contacts, i)
        end
    end
    --#endregion

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
--#endregion

--#region distance3D
assert(distance3D({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}) == 0, "distance3D test 1 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 1, y = 0, z = 0}) == 1, "distance3D test 2 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 0, y = 1, z = 0}) == 1, "distance3D test 3 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 1}) == 1, "distance3D test 4 failed")
assert(distance3D({x = 0, y = 0, z = 0}, {x = 1, y = 1, z = 1}) == math.sqrt(3), "distance3D test 5 failed")
--#endregion

--#region newTrack
track = Track({x = 0, y = 0, z = 0})
assert(track.coordinates[1].x == 0 and track.coordinates[1].y == 0 and track.coordinates[1].z == 0, "newTrack test 1 failed")
assert(track.tSinceUpdate == 0, "newTrack test 2 failed")
assert(track.angle == 0, "newTrack test 3 failed")
assert(track.speed == 0, "newTrack test 4 failed")
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
--#endregion

--#region updateTrackT
tracks = {Track({x = 0, y = 0, z = 0}), Track({x = 1, y = 1, z = 1})}
tracks = updateTrackT(tracks)
assert(tracks[1].tSinceUpdate == 1, "updateTrackT test 1 failed")
assert(tracks[2].tSinceUpdate == 1, "updateTrackT test 2 failed")
--#endregion

--#region newMatrix
matrix = newMatrix(2, 2, 0)
assert(matrix[1][1] == 0 and matrix[1][2] == 0 and matrix[2][1] == 0 and matrix[2][2] == 0, "newMatrix test 1 failed")
--#endregion

--#region areTablesEqual
assert(areTablesEqual({1, 2, 3}, {1, 2, 3}), "areTablesEqual test 1 failed")
assert(not areTablesEqual({1, 2, 3}, {1, 2, 4}), "areTablesEqual test 2 failed")
--#endregion
---@endsection