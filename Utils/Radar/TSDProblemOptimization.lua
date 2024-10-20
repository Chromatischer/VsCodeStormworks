-- Helper function to pad non-square matrices to square by adding "infinite" distances
function padMatrix(matrix)
    rows, cols = #matrix, #matrix[1]
    size = math.max(rows, cols) -- Find the larger dimension

    -- Pad rows with infinite distances
    for i = 1, rows do
        for j = cols + 1, size do
            matrix[i][j] = math.huge
        end
    end

    -- Add rows of infinite distances if necessary
    for i = rows + 1, size do
        matrix[i] = {}
        for j = 1, size do
            matrix[i][j] = math.huge
        end
    end

    table.insert(matrix, 1, vec(size, 0)) -- Add a leading row of infinite distances
    for i = 1, size do
        table.insert(matrix[i], 1, 0) -- Add a leading column of infinite distances
    end

    return matrix
end

-- Minimize total distance using Hungarian Algorithm with 0-based indexing
function minimizeDistance(a)
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

function vec(size, value)
    ret = {}
    value = value ~= nil and value or 0
    for i = 1, size do
        ret[i] = value
    end
    return ret
end

-- Function to generate a random matrix (2D array) with specified rows and columns
function generateRandomMatrix(rows, cols, maxValue)
    matrix = {}
    for i = 1, rows do
        matrix[i] = {}
        for j = 1, cols do
            matrix[i][j] = math.random(1, maxValue)
        end
    end
    return matrix
end

-- Improved function to test minimizeDistance with randomized input and formatted output
function testRandomizedMatrix(rows, cols, maxValue)
    -- Generate a random distance matrix
    randomMatrix = generateRandomMatrix(rows, cols, maxValue)

    -- Print the input matrix
    print("\nRandomized Input Matrix (" .. rows .. "x" .. cols .. "):")
    for i = 1, rows do
        for j = 1, cols do
            io.write(randomMatrix[i][j] .. "\t")
        end
        print()
    end

    -- Pad the matrix to make it square
    paddedMatrix = padMatrix(randomMatrix)

    -- Print the padded matrix (for visualization purposes)
    if rows ~= cols then
        print("\nPadded Matrix (to make it square):")
        for i = 1, #paddedMatrix do
            for j = 1, #paddedMatrix do
                if paddedMatrix[i][j] == math.huge then
                    io.write("i\t")
                else
                    io.write(paddedMatrix[i][j] .. "\t")
                end
            end
            print()
        end
    end

    -- Run the Hungarian algorithm to minimize distance
    result = minimizeDistance(paddedMatrix)

    -- Print the result: optimal matching
    print("\nOptimal Matching Result:")
    for i = 1, rows do
        print("Row " .. i .. " is matched with Column " .. result[i])
    end
end

-- Test the function with random input
testRandomizedMatrix(3, 5, 10)
