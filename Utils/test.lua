str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

for i = 1, #str do
    print(string.byte(str, i) - 65)
end