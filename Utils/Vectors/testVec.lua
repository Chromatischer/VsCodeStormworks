require("Utils.Vectors.vec3")
require("Utils.Vectors.vec2")

v = Vec3(1, 1, 1)
rad = 1
scalar = 10

for i = 1, 10, 1 do
    res = transformScalar(vec3ToVec2(v), rad, scalar * i)
    print(vec2toString(res))
end