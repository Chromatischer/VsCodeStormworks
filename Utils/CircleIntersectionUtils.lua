---**Use Trilateration instead, this is the wrong way to find the intersection points of circles**
---
---Finds the intersection points of two circles, if they intersect at all and returns them as a table
---@param circle1 table<x, y, r> The first circle to find the intersection points of (Table with x, y and radius r)
---@param circle2 table<x, y, r> The second circle to find the intersection points of (Table with x, y and radius r)
---@return table<x1, y1, x2, y2> ?table The intersection points of the two circles
---@return nil ?nil If the circles do not intersect
---@deprecated
---@section circleIntersection
function circleIntersection(circle1, circle2)
    x1 = circle1.x
    y1 = circle1.y
    r1 = circle1.r

    x2 = circle2.x
    y2 = circle2.y
    r2 = circle2.r

    centerDX = x1 - x2
    centerDY = y1 - y2
    R = math.sqrt(centerDX ^ 2 + centerDY ^ 2)
    if not (math.abs(r1 - r2 ) <= R and R <= r1 + r2) then
        return nil
    end

    R2 = R ^ 2
    R4 = R2 ^ 2

    a = (r1 ^ 2 - r2 ^ 2) / (2 * R2)
    r2r2 = (r1 ^ 2 - r2 ^ 2)
    c = math.sqrt(2 * (r1 ^ 2 + r2 ^ 2) / R2 - (r2r2 * r2r2) / R4 - 1)
    fx = (x1 + x2) / 2 + a * (x2 - x1)
    gx = c * (y2 - y1) / 2
    ix1 = fx + gx
    ix2 = fx - gx

    fy = (y1 + y2) / 2 + a * (y2 - y1)
    gy = c * (x1 - x2) / 2
    iy1 = fy + gy
    iy2 = fy - gy

    return {ix1, iy1, ix2, iy2}
end
---@endsection

---**Use Trilateration instead, this is the wrong way to find the intersection points of circles**
---
---Idea for finding the best intersection point:
---1. Find the intersection points of all circles
---2. Make an array of the distance from every intersection point to every other intersection point
---3. Find the intersection point with the smallest sum of distances to all other intersection points
---4. Return the intersection point with the smallest sum of distances to all other intersection points
---@param intersections table<table<x, y>> The points to find the best intersection point from
---@return table<x, y> coordinate best intersection point
---@return number distance Best distance to all other intersection points
---@return number number Number of calculations
---@deprecated
---@section findBestIntersectionPoint
function findBestIntersectionPoint(intersections)
    bestIntersection = {}
    bestDistance = math.huge
    number = 0
    for i = 1, #intersections do
        sum = 0
        for j = 1, #intersections do
            if i ~= j then
                sum = sum + math.sqrt((intersections[i].x - intersections[j].x) ^ 2 + (intersections[i].y - intersections[j].y) ^ 2)
                number = number + 1
            end
        end
        if sum < bestDistance then
            bestDistance = sum
            bestIntersection = intersections[i]
        end
    end
    return bestIntersection, bestDistance, number
end
---@endsection

---@section Testing
circles = {{x = 1, y = 1, r = 1}, {x = 0.1, y = 2.4, r = 1}, {x = 1.9, y = 2.5, r = 1}, {x = 2.1, y = 0.7, r = 1.7}, } -- 4 circles, which almost intersect at (1, 2)
intersections = {}
for i = 1, #circles do
    for j = i + 1, #circles do
        intersection = circleIntersection(circles[i], circles[j])
        if intersection then
            table.insert(intersections, intersection)
        end
    end
end
bestIntersection = findBestIntersectionPoint(intersections)
print("Best intersection point: " .. bestIntersection[1] .. ", " .. bestIntersection[2]) --Returns: 1.016, 1.999
---@endsection