str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

for i = 1, #str do
    char = string.sub(str, i, i)
    print(char .. " " .. char:byte() .. " " .. char:byte() - 65 .. " " .. tostring(char:byte() - 65 < 26 and char:byte() - 65 > -1) .. " " .. tostring(tonumber(char) ~= nil))
end

for i = 1, #str do
    char = string.sub(str, i, i)
    if tonumber(char) then
        print(char .. " " .. tonumber(char) .. " " .. tostring(tonumber(char) ~= nil))
    end
end