---Converts a bunch of information and the radar contact data to the global position of the radar contact
---@param contactDistance number the contact distance from the radar composite
---@param contactYaw number the contact azimuth from the radar composite
---@param contactPitch number the contact pitch from the radar composite
---@param gpsX number the gps X coordinate of the radar
---@param gpsY number the gps Y coordinate of the radar
---@param gpsZ number the gps Z coordinate of the radar
---@param compas number the compas direction of the vehicle
---@param pitch number the pitch tilt of the vehicle
---@return table<x, y, z> coordinate3D the global x, y and z position of the radar contact
---@section radarToGlobalCoordinates
function radarToGlobalCoordinates(contactDistance, contactYaw, contactPitch, gpsX, gpsY, gpsZ, compas, pitch)
    globalAngle = math.rad((contactYaw * 360 % 360) + compas * -360)
    x = contactDistance * math.sin(globalAngle)
    y = contactDistance * math.cos(globalAngle)
    globalPitch = math.rad((contactPitch * 360) + pitch * 360)
    z = contactDistance * math.tan(globalPitch)
    return {x = x + gpsX, y = y + gpsY, z = z + gpsZ}
end
---@endsection

---takes the output of the standard function and converts it to a coordinate object
---@param radarToGlobalCoordinate table coordinates
---@return Coordinate Coordinate the Coordinate object holding the same data as before
---@section convertToCoordinateObj
function convertToCoordinateObj(radarToGlobalCoordinate)
    return newCoordinate(radarToGlobalCoordinate.x, radarToGlobalCoordinate.y, radarToGlobalCoordinate.z)
end
---@endsection

---Converts the radar contact data to a global Vec3 object
---@param contactDistance number the contact distance from the radar composite
---@param contactYaw number the contact azimuth from the radar composite
---@param contactPitch number the contact pitch from the radar composite
---@param gpsX number the gps X coordinate of the radar
---@param gpsY number the gps Y coordinate of the radar
---@param gpsZ number the gps Z coordinate of the radar
---@param compas number the compas direction of the vehicle
---@param pitch number the pitch tilt of the vehicle
---@return Vec3 Vec3 the global Vec3 object of the radar contact
---@section radarToGlobalVec3
function radarToGlobalVec3(contactDistance, contactYaw, contactPitch, gpsX, gpsY, gpsZ, compas, pitch)
    temp = radarToGlobalCoordinates(contactDistance, contactYaw, contactPitch, gpsX, gpsY, gpsZ, compas, pitch)
    return Vec3(temp.x, temp.y, temp.z)
end
---@endsection

---Converts the radar contact data to a relative position from the vehicle
---@param contactDistance number the contact distance from the radar composite
---@param contactYaw number the contact azimuth from the radar composite
---@param contactPitch number the contact pitch from the radar composite
---@param compas number the compas direction of the vehicle
---@param pitch number the pitch tilt of the vehicle
---@return Vec3 Vec3 the relative position of the radar contact
---@section radarToRelativeVec3
function radarToRelativeVec3(contactDistance, contactYaw, contactPitch, compas, pitch)
    globalAngle = math.rad((contactYaw * 360 % 360) + compas * -360)
    x = contactDistance * math.sin(globalAngle)
    y = contactDistance * math.cos(globalAngle)
    globalPitch = math.rad((contactPitch * 360) + pitch * 360)
    z = contactDistance * math.tan(globalPitch)
    return Vec3(x, y, z)
end
---@endsection