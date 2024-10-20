SPEED_OF_SOUND = 700 -- m/s

---Calculates the time it takes for sound to travel a certain distance
---@param distance number Distance in meters
---@return number Time in seconds
---@section timeToWait
function timeToWait(distance)
    return distance / SPEED_OF_SOUND
end
---@endsection

---Calculates the distance from a certain time that the sound has traveled
---@param time number Time in seconds
---@return number Distance in meters
---@section distanceFromTime
function distanceFromTime(time)
    return time * SPEED_OF_SOUND
end
---@endsection