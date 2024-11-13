require("Utils.DataLink.DataLink")
require("Utils.Utils")
tbl = {}
for i = 1, 198 do
    --do transformation to transform 1 - 31 to a two letter String that is unique
    --use some mathematic function to transform i into a second number

    l = i / 198 * 25
    j = math.floor(l)
    k = math.floor((l - j) * 25)
    k = k == j and k + 1 or k

    tbl[i] = toChar(j) .. toChar(k)
--    print(i, toChar(j) .. toChar(k))
end

for i = 1, 198 do
    for j = 1, 198 do
        if tbl[i] == tbl[j] and i ~= j then
--            print("double at: " .. i .. " and " .. j .. " " .. tbl[i])
        end
    end
end


letters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}

for _, l1 in ipairs(letters) do
    for _, l2 in ipairs(letters) do
        str = l1 .. l2
        id, computable = IDFromString(str)
        if computable then
            print(string.format("%03d", id) .. " " .. str .. " " .. IDToString(id))
        end
    end
end

list = {}

for _, l1 in pairs(letters) do
    list[l1] = 0
end

for i = 1, 198 do
    k = string.sub(tbl[i], 1, 1)
    j = string.sub(tbl[i], 2, 2)
    list[k] = list[k] + 1 or 1
end

for i = 1, 26 do
    print(letters[i] .. " " .. list[letters[i]])
end