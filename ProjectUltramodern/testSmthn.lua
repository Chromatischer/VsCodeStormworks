require("Utils.Radar.HungarianAlgorithm")
tempRadarData = {3, 1, 2, 3, 6, 4, 4, 3}
twsTracks =     {0, 2, 3, 1, 5, 6, 9, 6}

hungarianMatrix = {}
for i = 1, #tempRadarData + 1 do
    hungarianMatrix[i] = vec(#twsTracks + 1, 0)
end

for i = 1, #tempRadarData do
    for j = 1, #twsTracks do
        hungarianMatrix[i + 1][j + 1] = math.abs(tempRadarData[i] - twsTracks[j])
    end
end

str = ""
for key, value in pairs(hungarianMatrix) do
    for key2, value2 in pairs(value) do
        str = str .. value2 .. " "
    end
    print(key, str)
    str = ""
end

res = hungarianAlgorithm(hungarianMatrix)

for row, col in pairs(res) do
    print("row: " .. row .. " col:" .. col .. " value" .. hungarianMatrix[row][col])
end