require("Utils.Coordinate.Coordinate")

---returns the distance for any 2D or 3D coordinate from the origin.
---@param x number the x coordinate
---@param y number the y coordinate
---@param z? number the z coordinate (optional if 2D)
---@return number number the distance from (0, 0, 0) or (0, 0) in case of 2D coordinate
---@section getDistanceFromOrigin
function getDistanceFromOrigin(x, y, z)
    if z then
        return newCoordinate(x, y, z):get3DDistanceTo(newCoordinate(0, 0, 0))
    else
        return newCoordinate(x, y):get2DDistanceTo(newCoordinate(0, 0))
    end
end
---@endsection