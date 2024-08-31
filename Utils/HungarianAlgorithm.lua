---Using the hungarianAlgorithm takes in a 2D matrix of values and optimizes the output for minimal values so that for each row, a column is selected
---takes in a table where the width and height (rows and columns) are the same. 
---Has to have a row of leading zeros. Has to have a 0 as the first element of each row
---@source https://en.wikipedia.org/wiki/Hungarian_algorithm#Connection_to_successive_shortest_paths
---@source this is not my code... I only adapted it to lua. I cannot find the original creator though it was (I think) from a scientific paper
---@param a table the 2D table to get the optimization of
---@return table table the optimal arrangement for minimal cost
---@section hungarianAlgorithm
function hungarianAlgorithm(a)
    HUGE = 9e3
    m = #a      --rows
    n = #a[1]   --columns
    u = vec(n + 1, 0)
    v = vec(m + 1, 0)
    p = vec(m + 1, 1)
    way = vec(m + 1, 0)
    for i = 1, n do
        p[1] = i
        j0 = 1
        minv = vec(m + 1, HUGE)
        used = vec(m + 1, false)
        repeat
            used[j0] = true
            i0 = p[j0]
            delta = HUGE
            local j1
            for j = 2, m do
                if used[j] ~= true then
                    cur = a[i0][j] - u[i0] - v[j]

                    if cur < minv[j] then
                        minv[j] = cur
                        way[j] = j0
                    end
                    if minv[j] < delta then
                        delta = minv[j]
                        j1 = j
                    end
                end
            end

            for j = 1, m do
                if used[j] == true then
                    u[p[j]] = u[p[j]] + delta
                    v[j] = v[j] - delta
                else
                    minv[j] = minv[j] - delta
                end
            end
            j0 = j1
        until p[j0] == 1
        repeat
            j1 = way[j0]
            p[j0] = p[j1]
            j0 = j1
        until j0 == 1
    end
    result = {}
    for i = 2, m do
        result[p[i]] = i
    end
    return result
end
---@endsection

---returns something like the c++ vec structure!
---@param size number the size of the array to create
---@param value ?any what number to put in by default if none is given will use 0
---@return table vec a table of the size size with all values being value
---@section vec
function vec(size, value)
    ret = {}
    value = value ~= nil and value or 0
    for i = 1, size do
        ret[i] = value
    end
    return ret
end
---@endsection

---Takes in any table and converts it into the format, the hungarianAlgorithm can use
---@param a table the table to convert
---@return table table the converted table, ready to be fed into the hungarianAlgorithm
---@section normalizeTable
function normalizeTable(a)
    row = #a
    col = #a[1]
    if row > col then --table is taller than long
        for i = 1, row do
            while #a[i] < row do --increasing table length by adding large values
                table.insert(a[i], 9e2)
            end
        end
    elseif col > row then --table is longer than tall
        while #a < col do --increasing table height by adding large rows
            table.insert(a, vec(col, 9e2))
        end
    end
    table.insert(a, 1, vec(#a)) --adding the top row of zeros
    for row = 1, #a do
        table.insert(a[row], 1, 0) --adding the leading column of zeros
    end
    return a
end
---@endsection

---small helper function to print a table to the console
---@param t table 2D table with rows and columns as well as saved values
---@section printTable
function printTable(t)
    for i = 1, #t do
        str = ""
        for l = 1, #t[i] do
            str = str .. (t[i][l] == 9e2 and "H" or t[i][l]) .. ", "
        end
        print(str)
    end
end
---@endsection

---will print the result of a hungarianAlgorithm execution to the console
---@param hungarianRes table output of the hungarianAlgorithm
---@param referenceTable table the input table to the hungarianAlgorithm
---@section printHungarianResults
function printHungarianResults(hungarianRes, referenceTable)
    for key, _ in pairs(hungarianRes) do
        key = key - 1
        print("row: " .. key + 1 .. " col: " .. hungarianRes[key + 1] .. " val: " .. (referenceTable[key + 1][hungarianRes[key + 1]] == 9e2 and "H" or referenceTable[key + 1][hungarianRes[key + 1]]))
    end
end
---@endsection

---@section buldin-tests
--table with the same number of rows as columns
h = {
    {4, 3, 1, 6, 5},
    {3, 2, 6, 4, 2},
    {7, 4, 3, 7, 9},
    {9, 9, 9, 9, 9},
    {9, 9, 9, 9, 9}
}

--table with more columns than rows
g = {
    {9, 0, 0, 3},
    {3, 4, 1, 2},
    {1, 2, 3, 4}
}

--table with more rows than columns
j = {
    {3, 3, 3},
    {2, 2, 2},
    {4, 5, 6},
    {1, 0, 2}
}

printTable(h)
print("------------")
normalizeTable(h)
printTable(h)
print("------------")
normalizeTable(g)
printTable(g)
print("------------")
printTable(j)
print("------------")
normalizeTable(j)
printTable(j)

res = hungarianAlgorithm(h)
printHungarianResults(res, h)

print("------------")

res2 = hungarianAlgorithm(g)
printHungarianResults(res2, g)

print("------------")

res3 = hungarianAlgorithm(j)
printHungarianResults(res3, j)
---@endsection