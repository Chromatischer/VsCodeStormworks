---calulate the distance between two coordinates
---@param p1 table<x, y> coordinate 1
---@param p2 table<x, y> coordinate 2
---@return number distance between the two coordinates
---@section distance
function distance(p1, p2)
    return math.sqrt((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2)
end
---@endsection

---calculate the mean squared error of the center and the beacons
---@param center table<x, y> center coordinate
---@param beacons table<table<x, y, distance>> beacons
---@return number mean squared error
---@section calcMeanSquaredError
function calcMeanSquaredError(center, beacons)
    local totalEroor = 0
    for _, beacon in ipairs(beacons) do
        totalEroor = totalEroor + (distance(center, beacon) - beacon.distance) ^ 2
    end
    return totalEroor
end
---@endsection

---calculate the average coordinate of a list of beacons
---@param beacons table<table<x, y, distance>> beacons
---@return table<x, y> coordinate average coordinate of the position of all the beacons
---@section averageCoordinate
function averageCoordinate(beacons)
    px = 0
    py = 0
    for _, beacon in ipairs(beacons) do
        px = px + beacon.x
        py = py + beacon.y
    end
    return {x = px / #beacons, y = py / #beacons}
end
---@endsection

---Calculat the center of the beacons using a gradient descend loop
---@param learnRate number the amount of change eatch loop (0.1)
---@param threshold number stopping threshold (0.0001)
---@param max_iterations number maximum iterations (1000)
---@param beacons table<table<x, y, distance>> beacons
---@param startPoint table<x, y> starting point
---@return table<x, y> coordinate the best center coordinate found
---@return number mse the mean squared error of the best center coordinate
---@return number numberOfIterations the number of iterations it took to find the best center coordinate before stopping because of the threshold
---@section gradientDescendLoop
function gradientDescendLoop(learnRate, threshold, max_iterations, beacons, startPoint)
    local numberOfIterations = 0
    for i = 1, max_iterations do
        mse = calcMeanSquaredError(startPoint, beacons)
        local gradX, gradY = 0, 0
        for _, beacon in ipairs(beacons) do
            local predicedDistance = distance(startPoint, beacon)
            if predicedDistance ~= 0 then
                local diff = predicedDistance - beacon.distance
                gradX = gradX + (diff * (startPoint.x - beacon.x) / predicedDistance)
                gradY = gradY + (diff * (startPoint.y - beacon.y) / predicedDistance)
            end
        end

        gradX = (#beacons * gradX) / 2
        gradY = (#beacons * gradY) / 2

        startPoint.x = startPoint.x - learnRate * gradX --seems to be a bug in the code of the highlighter and not me...
        startPoint.y = startPoint.y - learnRate * gradY --take a look at this: https://github.com/LuaLS/lua-language-server/issues/2746 I think!

        numberOfIterations = numberOfIterations + 1
        if math.abs(gradX) < threshold and math.abs(gradY) < threshold then
            break
        end
    end
    return startPoint, mse, numberOfIterations
end
---@endsection


---@section Testing
local beacons = {
    {x = 0, y = 0, distance = 5},
    {x = 10, y = 0, distance = 5},
    {x = 5, y = 10, distance = 5}
}

local bestPoint, mse, numberOfIterations = gradientDescendLoop(0.1, 0.001, 100, beacons, averageCoordinate(beacons))
print("Average Point: ", averageCoordinate(beacons).x, averageCoordinate(beacons).y)
print("Best Point: ", bestPoint.x, bestPoint.y)
print("MSE: ", mse)
print("Number of Iterations: ", numberOfIterations)

--Returns: 5, 3.6
--MSE: 4.6
--proof that this is correct: https://www.desmos.com/calculator/hbwmir6brc?lang=de
---@endsection