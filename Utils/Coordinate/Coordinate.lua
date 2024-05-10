--TODO: fix the fact that the coordinate does not know if it is 2D or 3D and will return a Z coorinate nevertheless!

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

        getX = function(self)
            return self.x
        end,

        getY = function(self)
            return self.y
        end,

        getZ = function(self)
            return self.z --this should return nil but does not! Why?
        end,

        getIs2D = function(self)
            return self.is2D
        end,

        getCoordinates = function(self)
            return self.x, self.y, self.z
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
                ret = math.sqrt((self.x - coordinate:getX()) ^ 2 + (self.y - coordinate:getY()) ^ 2 + (self.z - coordinate:getZ()) ^ 2)
                if isInf(ret) or isNan(ret) or ret == nil then
                    print("raaaa!")
                else
                    return ret
                end
            else
                print("boo!")
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
            self.x = self.x + x
            self.y = self.y + y
            if not self.is2D and not z == nil then
                self.z = self.z + z
            else
            --     ---@section __LB_SIMULATOR_ONLY__
            --     if self.is2D and z then
            --         error("unable to add 3D position to 2D coordinate!")
            --     end
            --     if z == nil and not self.is2D then
            --         error("Z is nil where a 3D coordinate is expected!")
            --     end
            end
            -- ---@endsection
        end,
        ---@endsection
        
        ---add X, Y and Z to the coordinates. WILL NOT CONVERT THE COORDINATE INTO A 3D WHEN ADDING Z
        ---@param x number the X increment
        ---@param y number the Y increment
        ---@section add
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
        end
        ---@endsection
    }
    return newObj
end