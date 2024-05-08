---creates a new coordinate with the specified X and Y position
---@param x number the X coordinate of the Coordinate
---@param y number the Y coordinate of the Coordinate
---@param z? number optional the Z coordinate of the Coordinate
---@return table
function newCoordinate(x, y, z)
    local newObj = {
        x = x,
        y = y,
        is2D = (z == nil),
        z = z == nil and 0 or z,

        getX = function(self)
            return self.x
        end,

        getY = function(self)
            return self.y
        end,

        getZ = function(self)
            return self.is2D and nil or self.z
        end,

        getIs2D = function(self)
            return self.is2D
        end,

        getCoordinates = function(self)
            return self.x, self.y, self.is2D and nil or self.z
        end,

        setCoordinates = function(self, setX, setY, setZ)
            self.is2D = not z == nil
            self.x = setX
            self.y = setY
            self.z = setZ
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

        ---add X, Y and Z to the coordinates. WILL NOT CONVERT THE COORDINATE INTO A 3D WHEN ADDING Z
        ---@param x number the X increment
        ---@param y number the Y increment
        ---@param z? number the Z increment
        ---@section add
        add = function(self, x, y, z)
            print(x, y, z)
            z = z == nil and 0 or z
            self.x = self.x + x
            self.y = self.y + y
            self.z = self.is2D and self.z or self.z + z
        end,
        ---@endsection

        ---overrides if the coordinate is considered 2D or 3D
        ---@param state boolean the new state (true is 2D coordinate)
        ---@section setIs2D
        setIs2D = function(self, state)
            self.is2D = state
        end
        ---@endsection
    }
    return newObj
end

-- ---@section __LB_SIMULATOR_ONLY__
-- first = newCoordinate(0, 0)
-- second = newCoordinate(0, 1, 1)
-- third = newCoordinate(0, 0, 0)
-- print(math.deg(first:get2DAngleTo(second)))
-- print(first:getIs2D())
-- print(second:getIs2D())
-- print(third:getIs2D())
-- print(second:get3DDistanceTo(third))
-- ---@endsection
--
first = newCoordinate(0, 0)
print(first:getIs2D())
print(first:getX(), first:getY(), first:getZ())
first:setIs2D(false)
first:add(1, 1, 1)
print(first:getX(), first:getY(), first:getZ())
print(first:getIs2D())