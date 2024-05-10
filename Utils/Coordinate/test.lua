require("Utils.Coordinate.Coordinate")
require("Utils.Coordinate.Coordinate_Utils")
require("Utils.Utils")
require("Utils.Coordinate.radarToGlobalCoordinates")

first = newCoordinate(-1, -1, -1)
second = newCoordinate(0, 0, 0)
third = newCoordinate(1, 1, 1)
fourth = newCoordinate(-2, -2, -2)
fifth = newCoordinate(2, 2)

print(first:get3DDistanceTo(second))
print(first:get3DDistanceTo(third))
print(first:get3DDistanceTo(fourth))
print(first:get3DDistanceTo(fifth))

print(-math.huge < 0)

rtgc = radarToGlobalCoordinates(25, 0, 0, 10, 10, 10, 0, 0)
print(rtgc.x .. " " .. rtgc.y .. " " .. rtgc.z)

rtgcC = convertToCoordinateObj(rtgc)
print(rtgcC:getX() .. " " .. rtgcC:getY() .. " " .. rtgcC:getZ())