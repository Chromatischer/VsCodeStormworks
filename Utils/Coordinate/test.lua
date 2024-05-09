require("Utils.Coordinate.Coordinate")
require("Utils.Coordinate.Coordinate_Utils")
require("Utils.Utils")

first = newCoordinate(-1, -1, -1)
second = newCoordinate(0, 0, 0)
third = newCoordinate(1, 1, 1)
fourth = newCoordinate(-2, -2, -2)
fifth = newCoordinate(2, 2)

print(first:get3DDistanceTo(second))
print(first:get3DDistanceTo(third))
print(first:get3DDistanceTo(fourth))
print(first:get3DDistanceTo(fifth))