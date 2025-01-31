SPEED_OF_SOUND = 740 -- m/s -> 740 / 60 = 12.33 m/tick

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

---Converts seconds to ticks
---@param time number Seconds
---@return number Ticks
---@section secondsToTicks
function secondsToTicks(time)
    return time * 60
end
---@endsection

---Converts ticks to seconds
---@param ticks number Ticks
---@return number Seconds
---@section ticksToSeconds
function ticksToSeconds(ticks)
    return ticks / 60
end
---@endsection


---Calculates the position of a sonar contact
---@class SonarContact
---@field distance number Distance to the contact in meters
---@field globalPosition Vec3 Global position of the contact
---@param pivot number Relative angle to the contact
---@param pitch number Relative pitch to the contact
---@param timeSincePulse number Time since the last pulse in ticks
---@param vesselAngle number Global angle of the vessel
---@param vesselPitch number Global pitch of the vessel
---@param gpsX number Global X position of the vessel
---@param gpsY number Global Y position of the vessel
---@param gpsZ number Global Z position of the vessel
---@return SonarContact SonarContact new sonar contact object\
---@section SonarContact
function SonarContact(pivot, pitch, timeSincePulse, vesselAngle, vesselPitch, gpsX, gpsY, gpsZ)
    globalAngle = math.rad((vesselAngle + pivot) % 360) --degrees + degrees = degrees
    globalPitch = math.rad((vesselPitch + pitch) % 360)
    distance = distanceFromTime(ticksToSeconds(timeSincePulse))
    globalX = gpsX + distance * math.cos(globalAngle) * math.cos(math.rad(globalPitch))
    globalY = gpsY + distance * math.sin(globalAngle) * math.cos(math.rad(globalPitch))
    globalZ = gpsZ + distance * math.sin(globalAngle)
    return {
        distance = distance,
        globalPosition = Vec3(globalX, globalY, globalZ),
        age = 200,
    }
end
---@endsection

---Updates the age of a sonar contact
---@class SonarContact
---@field updateSonarContact function Updates the age of the sonar contact
---@field age number Age of the sonar contact
---@param self SonarContact Sonar contact object
---@section updateSonarContact
function updateSonarContact(self)
    self.age = self.age - 1
end
---@endsection

---Checks if a sonar contact is deprecated
---@class SonarContact
---@field contactDeprecated function Checks if the sonar contact is deprecated
---@param self SonarContact Sonar contact object
---@return boolean True if the sonar contact is deprecated
---@section contactDeprecated
function contactDeprecated(self)
    return self.age <= 0
end
---@endsection