---This function will return the minimum value of the matrix where each column can only have one row
---given an array like:
---h = {{0, 0, 0, 0}, {0, 4, 3, 1}, {0, 3, 2, 6}, {0, 7, 4, 3}}
---the return will be: r1 = 3, r2 = 1, r3 = 2 for a total of 8
---this can be useful for tws radars!
---@param a table matrix with length m and width n
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

---@section buldin-tests
h = {
    {0, 0, 0, 0},
    {0, 4, 3, 1},
    {0, 3, 2, 6},
    {0, 7, 4, 3}
}

res = hungarianAlgorithm(h)

cost = 0
for row, col in pairs(res) do
    print("row: " .. (row - 1) .. " col: " .. (col - 1))
    cost = cost + h[row][col]
end

print("cost: " .. cost)
---@endsection