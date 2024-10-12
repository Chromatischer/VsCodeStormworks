---Creates a new Vec3 object
---@class Vec3
---@param x ?number the x component of the vector
---@param y ?number the y component of the vector
---@param z ?number the z component of the vector
---@return Vec3 the new vector
---@section Vec3
function Vec3(x, y, z)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
    }
end
---@endsection

---Multiplies the vector by a scalar and returns a new vector with the result
---@class Vec3
---@field multiply function multiplies the vector by a scalar and returns a new vector with the result
---@param self Vec3 the vector
---@param scalar number the scalar
---@return Vec3 the new vector with the result
---@section multiply
function multiply(self, scalar)
    return Vec3(self.x * scalar, self.y * scalar, self.z * scalar)
end
---@endsection

---Divides the vector by a scalar and returns a new vector with the result
---@class Vec3
---@field divide function divides the vector by a scalar and returns a new vector with the result
---@param self Vec3 the vector
---@param scalar number the scalar
---@return Vec3 the new vector with the result
---@section divide
function divide(self, scalar)
    return Vec3(self.x / scalar, self.y / scalar, self.z / scalar)
end
---@endsection

---Converts the vector to a Vec2 object
---@class Vec3
---@field toVec2 function converts the vector to a Vec2 object
---@param self Vec3 the vector
---@return Vec2 the vector as a Vec2 object
---@section toVec2
function toVec2(self)
    return Vec2(self.x, self.y)
end
---@endsection

---Returns the distance to another vector
---@class Vec3
---@field distanceToVec3 function returns the distance to another vector
---@param self Vec3 the vector
---@param other Vec3 the other vector
---@return number the distance to the other vector
---@section distanceToVec3
function distanceToVec3(self, other)
    return math.sqrt((self.x - other.x) ^ 2 + (self.y - other.y) ^ 2 + (self.z - other.z) ^ 2)
end
---@endsection

---Returns the length of the vector
---@class Vec3
---@field vec3length function returns the length of the vector
---@param self Vec3 the vector
---@return number the length of the vector
---@section vec3length
function vec3length(self)
    return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
end
---@endsection

---Adds the second Vec3 values to itself
---@class Vec3
---@field addVec3 function adds the second Vec3 values to itself
---@param self Vec3 the vector
---@param other Vec3 the other vector
---@section addVec3
function addVec3(self, other)
    self.x = self.x + other.x
    self.y = self.y + other.y
    self.z = self.z + other.z
end
---@endsection

---Sums the whole table of Vec3 values to itself
---@class Vec3
---@field sumTableVec3 function sums the whole table of Vec3 values to itself
---@param self Vec3 the vector
---@param table table<Vec3> the table of vectors
---@return Vec3 self itself with the summed values
---@section sumTableVec3
function sumTableVec3(self, table)
    for _, vector in ipairs(table) do
        self = self:addVec3(vector)
    end
    return self
end
---@endsection