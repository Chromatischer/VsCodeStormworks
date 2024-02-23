---calculate the distance between two coordinates 
---@param a Coordinate first coordinate
---@param b Coordinate second coordinate
---@return number number the distance between Coordinate A and B
function Coordinate.distance(a,b)
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2)
end

---calculate the angle between two coordinates
---@param a Coordinate first coordinate
---@param b Coordinate second coordinate
---@return number number the angle between Coordinate a and b
function Coordinate.angle(a,b)
    return math.deg(math.atan(b.y-a.y,b.x-a.x))
end