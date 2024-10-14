---Creates a new 2D vector
---@class Vec2
---@field x number the x component of the vector
---@field y number the y component of the vector
---@param x ?number the x component of the vector
---@param y ?number the y component of the vector
---@return Vec2 the new vector
---@section Vec2
function Vec2(x, y)
    return {
        x = x or 0,
        y = y or 0
    }
end
---@endsection

---Returns the distance between two vectors
---@class Vec2
---@field distanceToVec2 function returns the distance between two vectors
---@param self Vec2 the first vector
---@param other Vec2 the second vector
---@return number the distance between the two vectors
---@section distanceToVec2
function distanceToVec2(self, other)
    return math.sqrt((self.x - other.x) ^ 2 + (self.y - other.y) ^ 2)
end
---@endsection

---Returns the angle between two vectors
---@class Vec2
---@field angleTo function returns the angle between two vectors
---@param self Vec2 the first vector
---@param other Vec2 the second vector
---@return number the angle between the two vectors (radians)
---@section angleTo
function angleTo(self, other)
    return math.atan(self.y - other.y, self.x - other.x)
end
---@endsection

---Adds two vectors and retruns a new vector with the result
---@class Vec2
---@field addVec2 function adds two vectors and returns a new vector with the result
---@param self Vec2 the first vector
---@param other Vec2 the second vector
---@return Vec2 the new vector with the result
---@section addVec2
function addVec2(self, other)
    return Vec2(self.x + other.x, self.y + other.y)
end
---@endsection

---Subtracts two vectors and returns a new vector with the result
---@class Vec2
---@field subtract function subtracts two vectors and returns a new vector with the result
---@param self Vec2 the first vector
---@param other Vec2 the second vector
---@return Vec2 the new vector with the result
---@section subtract
function subtract(self, other)
    return Vec2(self.x - other.x, self.y - other.y)
end
---@endsection

---Returns the dot product of two vectors
---@class Vec2
---@field dotProduct function returns the dot product of two vectors
---@param self Vec2 the first vector
---@param other Vec2 the second vector
---@return number the dot product of the two vectors
---@section dotProduct
function dotProduct(self, other)
    return self.x * other.x + self.y * other.y
end
---@endsection

---Returns the cross product of two vectors
---@class Vec2
---@field crossProduct function returns the cross product of two vectors
---@param self Vec2 the first vector
---@param other Vec2 the second vector
---@return number the cross product of the two vectors
---@section crossProduct
function crossProduct(self, other)
    return self.x * other.y - self.y * other.x
end
---@endsection

---Returns the length of the vector
---@class Vec2
---@field vec2length function returns the length of the vector
---@param self Vec2 the vector
---@return number the length of the vector
---@section vec2length
function vec2length(self)
    return math.sqrt(self.x ^ 2 + self.y ^ 2)
end
---@endsection

---Returns the normalized vector
---@class Vec2
---@field normalize function returns the normalized vector
---@param self Vec2 the vector
---@return Vec2 the normalized vector
---@section normalize
function normalize(self)
    local len = length(self)
    return Vec2(self.x / len, self.y / len)
end
---@endsection

---Multiplies the vector by a scalar and returns a new vector with the result
---@class Vec2
---@field scalarMultiply function multiplies the vector by a scalar and returns a new vector with the result
---@param self Vec2 the vector
---@param scalar number the scalar
---@return Vec2 the new vector with the result
---@section scalarMultiply
function scalarMultiply(self, scalar)
    return Vec2(self.x * scalar, self.y * scalar)
end
---@endsection

---Divides the vector by a scalar and returns a new vector with the result
---@class Vec2
---@field scalarDivide function divides the vector by a scalar and returns a new vector with the result
---@param self Vec2 the vector
---@param scalar number the scalar
---@return Vec2 the new vector with the result
---@section scalarDivide
function scalarDivide(self, scalar)
    return Vec2(self.x / scalar, self.y / scalar)
end
---@endsection

---Adds a scalar to the x component of the vector and returns a new vector with the result
---@class Vec2
---@field addX function adds a scalar to the x component of the vector and returns a new vector with the result
---@param self Vec2 the vector
---@param x number the scalar
---@return Vec2 the new vector with the result
---@section addX
function addX(self, x)
    return Vec2(self.x + x, self.y)
end
---@endsection

---Adds a scalar to the y component of the vector and returns a new vector with the result
---@class Vec2
---@field addY function adds a scalar to the y component of the vector and returns a new vector with the result
---@param self Vec2 the vector
---@param y number the scalar
---@return Vec2 the new vector with the result
---@section addY
function addY(self, y)
    return Vec2(self.x, self.y + y)
end
---@endsection

---Returns the vector as a string
---@class Vec2
---@field vec2toString function returns the vector as a string
---@param self Vec2 the vector
---@return string the vector as a string
---@section vec2toString
function vec2toString(self)
    return "(" .. self.x .. ", " .. self.y .. ")"
end
---@endsection

---transform using an angle in radians and a scalar and returns a new Vec2
---@class Vec2
---@field transformScalar function transform using an angle in rad and a scalar and returns a new Vec2
---@param self Vec2 the Vector
---@param rad number the angle to transform by in radians
---@param scalar number the scalar of the transformation
---@return Vec2 Vec2 the new vector multiplied by the scalar and rotated by the angle
---@section transformScalar
function transformScalar(self, rad, scalar)
    return Vec2(self.x + (scalar * math.sin(rad)), self.y + (scalar * math.cos(rad)))
end
---@endsection

---Converts a Vec2 to a Vec3 with the specified z value or 0
---@param self Vec2 the vector
---@param z ?number the z component of the new vector
---@return Vec3 Vec3 the new vector with the specified z value or 0
---@section vec2ToVec3
function vec2ToVec3(self, z)
    return Vec3(self.x, y, z or 0)
end
---@endsection