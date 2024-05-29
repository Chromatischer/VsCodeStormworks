---creates a new coordinate with the specified X and Y position
---@param x number the X coordinate of the Coordinate
---@param y number the Y coordinate of the Coordinate
---@param z? number optional the Z coordinate of the Coordinate
---@return table Coordinate the newly created coordinate
function newCoordinate(x, y, z)
    local newObj = {
        x = x,
        y = y,
        is2D = (z == nil), --this is working!
        z = z,

        ---@section getX
        getX = function(self)
            return self.x
        end,
        ---@endsection

        ---@section getY
        getY = function(self)
            return self.y
        end,
        ---@endsection

        ---@section getZ
        getZ = function(self)
            return self.z --this should return nil but does not! Why?
        end,
        ---@endsection

        ---@section getIs2D
        getIs2D = function(self)
            return self.is2D
        end,
        ---@endsection

        ---@section getCoordinates
        getCoordinates = function(self)
            return self.x, self.y, self.z
        end,
        ---@endsection

        ---@section setCoordinates
        setCoordinates = function(self, setX, setY, setZ)
            self.is2D = not z == nil
            self.x = setX
            self.y = setY
            self.z = setZ
        end,
        ---@endsection

        ---This function returns 2D the distance between the Coordinate A and B
        ---@param coordinate Coordinate the coordinate to get the distance to
        ---@return number number the distance to that coordinate
        ---@section distanceToCoordinate
        get2DDistanceTo = function(self, coordinate)
            return math.sqrt((self.x - coordinate:getX()) ^ 2 + (self.y - coordinate:getY()) ^ 2)
        end,
        ---@endsection

        ---This function returns the 3D distance between the Coordinate A and B
        ---@param coordinate Coordinate the coordinate to get the distance to
        ---@return number number the distance to that coordinate
        ---@section distanceToCoordinate3D
        get3DDistanceTo = function(self, coordinate)
            if not self.is2D and not coordinate:getIs2D() then
                ret = math.sqrt((self.x - coordinate:getX()) ^ 2 + (self.y - coordinate:getY()) ^ 2 + (self.z - coordinate:getZ()) ^ 2)
            end
            return ret
        end,
        ---@endsection

        ---This function returns the angle between the line that connects point A to point B above the X-Axis. Given (0, 0) (1, 0) it will return 0.0deg
        ---@param coordinate Coordinate the second coordinate
        ---@return number float the angle between the two Coordinates above the X-Axis in radians
        ---@section angleToCoordinate
        get2DAngleTo = function(self, coordinate)
            return math.atan(coordinate:getY() - self.y, coordinate:getX() - self.x)
        end,
        ---@endsection

        ---add X, Y and Z to the coordinates. WILL NOT CONVERT THE COORDINATE INTO A 3D WHEN ADDING Z
        ---@param x number the X increment
        ---@param y number the Y increment
        ---@param z? number the Z increment
        ---@section add
        add = function(self, x, y, z)
            self.x = self.x + x
            self.y = self.y + y
            if not self.is2D and not z == nil then
                self.z = self.z + z
            end
        end,
        ---@endsection

        ---add X, Y and Z to the coordinates. WILL NOT CONVERT THE COORDINATE INTO A 3D WHEN ADDING Z
        ---@param x number the X increment
        ---@param y number the Y increment
        ---@section add2D
        add2D = function(self, x, y)
            self.x = self.x + x
            self.y = self.y + y
        end,
        ---@endsection

        ---overrides if the coordinate is considered 2D or 3D
        ---@param state boolean the new state (true is 2D coordinate)
        ---@section setIs2D
        setIs2D = function(self, state)
            self.is2D = state
            if state == false and self.z == nil then
                self.z = 0
            end
        end,
        ---@endsection

        ---returns the X, Y and Z coordinate as the string
        ---@return string string the string
        ---@section getStr
        getString = function (self)
            return "X: " .. self.x .. " Y: " .. self.y  .. " Z: " .. self.z
        end,
        ---@endsection

        ---returns the pitch and yaw angle to the coordinate if not 3D will return 0 for pitch and the yaw angle
        ---@param coordinate Coordinate the coordinate to get the angle to
        ---@return number number the pitch angle
        ---@return number number the yaw angle
        ---@section get3DAngleTo
        get3DAngleTo = function(self, coordinate)
            local dx = coordinate:getX() - self.x
            local dy = coordinate:getY() - self.y
            local dz = coordinate:getZ() - self.z
            local pitch = math.atan(dy, math.sqrt(dx^2 + dz^2))
            local yaw = math.atan(dx, dz)
            if not self.is2D and not coordinate:getIs2D() then
                return pitch, yaw
            end
                return 0, yaw
        end,
        ---@endsection
    }
    return newObj
end