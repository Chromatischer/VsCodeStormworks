---creates a new coordinate with the specified X and Y position
---@param x number the X coordinate of the Coordinate
---@param y number the Y coordinate of the Coordinate
---@param z? number optional the Z coordinate of the Coordinate
---@return table
function newCoordinate(x, y, z)
    local newObj = {
        x = x,
        y = y,
        is2D = z == nil,
        z = z == nil and 0 or z,

        getX = function(self)
            return self.x
        end,

        getY = function(self)
            return self.y
        end,

        getZ = function(self)
            return self.z
        end,

        getIs2D = function(self)
            return self.is2D
        end,

        getCoordinates = function(self)
            return self.x, self.y, self.z
        end,

        setCoordinates = function(self, x, y, z)
            self.is2D = not z == nil
            self.z = z
            self.x = x
            self.y = y
        end,

        ---This function returns 2D the distance between the Coordinate A and B
        ---@param coordinate Coordinate the coordinate to get the distance to
        ---@return number number the distance to that coordinate
        ---@section distanceToCoordinate
        get2DDistanceTo = function(self, coordinate)
            return math.sqrt((self.x - coordinate:getX()) ^ 2 + (self.y - coordinate:getY()) ^ 2)
        end,
        ---@endsection

        get3DDistanceTo = function(self, coordinate)
            if not self.is2D and not coordinate:getIs2D() then
                return math.sqrt((self.x - coordinate:getX()) ^ 2 + (self.y - coordinate:getY()) ^ 2 +
                    (self.z - coordinate:getZ()) ^ 2)
            end
        end,

        ---This function returns the angle between the line that connects point A to point B above the X-Axis. Given (0, 0) (1, 0) it will return 0.0deg
        ---@param coordinate Coordinate the second coordinate
        ---@return number float the angle between the two Coordinates above the X-Axis in radians
        ---@section angleToCoordinate
        get2DAngleTo = function(self, coordinate)
            return math.atan(coordinate:getY() - self.y, coordinate:getX() - self.x)
        end,
        ---@endsection

        ---add X, Y and Z to the coordinates
        ---@param x number the X increment
        ---@param y number the Y increment
        ---@param z? number the Z increment
        ---@section add
        add = function(self, x, y, z)
            z = z == nil and 0 or z
            self.x = self.x + x
            self.y = self.y + y
            self.z = self.z == nil and nil or self.z + z
        end
        ---@endsection
    }
    return newObj
end

---@section testing
first = newCoordinate(0, 0)
second = newCoordinate(0, 1, 1)
third = newCoordinate(0, 0, 0)
print(math.deg(first:get2DAngleTo(second)))
print(first:getIs2D())
print(second:getIs2D())
print(third:getIs2D())
print(second:get3DDistanceTo(third))
---@endsection