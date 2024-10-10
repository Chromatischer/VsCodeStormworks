---Draws an icon from a string representation of a matrix. Format of the string is a 1 for a pixel and a 0 for no pixel
---@param matrixString string the string representation of the matrix
---@param rows number the number of rows in the matrix
---@param cols number the number of columns in the matrix
---@param x number the start X position of the icon
---@param y number the start Y position of the icon
---@section drawMatrixFromString
function drawMatrixFromString(matrixString, rows, cols, x, y)
    for i = 1, rows do
        for j = 1, cols do
            local strpos = (i - 1) * rows + j
            local charAtPos = matrixString:sub(strpos, strpos)
            if charAtPos == "1" then
                screen.drawLine(x + j, y + i, x + j + 1, y + i)
            end
        end
    end
end
---@endsection