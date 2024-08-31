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