---@param size number the size of the matrix (sqare)
---@return Matrix Matrix a new matrix object
---@section Matrix
function Matrix(size)
    return RectMatrix(size, size)
end
---@endsection

---@class Matrix
---@param width number the width of the matrix
---@param height number the height of the matrix
---@return Matrix Matrix a new matrix object
---@section rectMatrix
function RectMatrix(width, height)
    return {
        width = width,
        height = height,
        data = {},
    }
end
---@endsection

---@class Matrix
---@field sizeEqual function check if the size of the matrix is equal to another matrix
---@param self Matrix the matrix object
---@param other Matrix the other matrix to compare with
---@return boolean boolean True if the size of the matrix is equal to the other matrix
---@section sizeEqual
function sizeEqual(self, other)
    return self.width == other.width and self.height == other.height
end
---@endsection

---@class Matrix
---@field flood function fill the matrix with a value at every cell
---@param self Matrix the matrix object
---@param value any the value to fill the matrix with
---@section flood
function flood(self, value)
    --should work for both square and rectangular matrices
    for i = 1, self.width do
        self.data[i] = {}
        for j = 1, self.height do
            self.data[i][j] = value
        end
    end
    return self
end
---@endsection

---@class Matrix
---@field getCell function get the value of a cell in the matrix
---@param self Matrix the matrix object
---@param x number the x position of the cell
---@param y number the y position of the cell
---@return any Value the value of the cell at the position (x, y)
---@section getCell
function getCell(self, x, y)
    return self.data[x][y]
end
---@endsection

---@class Matrix
---@field setCell function set the value of a cell in the matrix
---@param self Matrix the matrix object
---@param x number the x position of the cell
---@param y number the y position of the cell
---@param value any the value to set the cell to
---@return Matrix Matrix the modified matrix object
---@section setCell
function setCell(self, x, y, value)
    self.data[x][y] = value
    return self
end
---@endsection

---@class Matrix
---@field getRow function get a row of the matrix
---@param self Matrix the matrix object
---@param x number the position of the row
---@return table the row of the matrix
---@section getRow
function getRow(self, x)
    return self.data[x]
end
---@endsection

---@class Matrix
---@field getColumn function get a column of the matrix
---@param self Matrix the matrix object
---@param y number the position of the column
---@return table Table the column of the matrix at the position y
---@section getColumn
function getColumn(self, y)
    column = {}
    for i = 1, self.width do
        column[i] = self.data[i][y]
    end
    return column
end
---@endsection

---@class Matrix
---@field multiplyMatrix function multiply the matrix with another matrix
---@param self Matrix the matrix object
---@param other Matrix the other matrix to multiply with
---@return Matrix Matrix the result of the multiplication
---@section multiplyMatrix
function multiplyMatrix(self, other)
    result = flood(RectMatrix(self.width, self.height), 0)
    if sizeEqual(self, other) then
        for i = 1, self.width do
            for j = 1, self.height do
                for k = 1, self.width do
                    result.data[i][j] = result.data[i][j] + self.data[i][k] * other.data[k][j]
                end
            end
        end
    else
        print("ERR")
    end
    return result
end
---@endsection

---@class Matrix
---@field addMatrix function add the values of the matrix to another matrix
---@param self Matrix the matrix object
---@param other Matrix the other matrix to add with
---@return Matrix Matrix the result of the addition
---@section addMatrix
function addMatrix(self, other)
    result = flood(RectMatrix(self.width, self.height), 0)
    if sizeEqual(self, other) then
        for i = 1, self.width do
            for j = 1, self.height do
                result.data[i][j] = self.data[i][j] + other.data[i][j]
            end
        end
    end
    return result
end
---@endsection


---@class Matrix
---@field subtractMatrix function subtract the values of the matrix from another matrix
---@param self Matrix the matrix object
---@param other Matrix the other matrix to subtract from
---@return Matrix Matrix the result of the subtraction
---@section subtractMatrix
function subtractMatrix(self, other)
    result = flood(RectMatrix(self.width, self.height), 0)
    if sizeEqual(self, other) then
        for i = 1, self.width do
            for j = 1, self.height do
                result.data[i][j] = self.data[i][j] - other.data[i][j]
            end
        end
    end
    return result
end
---@endsection

---@class Matrix
---@field sumMatrix function sum the values of the matrix
---@param self Matrix the matrix object
---@return number Number the sum of the values in the matrix
---@section sumMatrix
function sumMatrix(self)
    sum = 0
    for i = 1, self.width do
        for j = 1, self.height do
            sum = sum + self.data[i][j]
        end
    end
    return sum
end
---@endsection

---@class Matrix
---@field averageMatrix function average the values of the matrix
---@param self Matrix the matrix object
---@return number Number the average of the values in the matrix
---@section averageMatrix
function averageMatrix(self)
    return sumMatrix(self) / (self.width * self.height)
end
---@endsection

---@class Matrix
---@field scaleMatrix function scale the values of the matrix
---@param self Matrix the matrix object
---@param scalar number the scalar to multiply the values with
---@return Matrix Matrix the result of the scaling
---@section scaleMatrix
function scaleMatrix(self, scalar)
    result = flood(RectMatrix(self.width, self.height), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            result.data[i][j] = self.data[i][j] * scalar
        end
    end
    return result
end
---@endsection

---@class Matrix
---@field transpose function copy the matrix
---@param self Matrix the matrix object
---@return Matrix Matrix the copied matrix
---@section transpose
function transpose(self)
    result = flood(RectMatrix(self.height, self.width), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            result.data[j][i] = self.data[i][j]
        end
    end
    return result
end
---@endsection

---@class Matrix
---@field determinant function calculate the determinant of the matrix
---@param self Matrix the matrix object
---@return number Number the determinant of the matrix
---@section determinant
function determinant(self)
    if self.width == 2 then
        return self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]
    end
    det = 0
    for i = 1, self.width do
        det = det + self.data[1][i] * cofactor(self, 1, i)
    end
    return det
end
---@endsection

---@class Matrix
---@field minorOf function get the minor of the matrix
---@param self Matrix the Matrix to get the minor of
---@return Matrix Matrix the minor of the input matrix
---@section minorOf
function minorOf(self, x, y)
    minor = flood(RectMatrix(self.width - 1, self.height - 1), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            if i ~= x and j ~= y then
                minor.data[i > x and i - 1 or i][j > y and j - 1 or j] = self.data[i][j]
            end
        end
    end
    return minor
end
---@endsection

---@class Matrix
---@field cofactor function calculate the cofactor of the matrix
---@param self Matrix the matrix object
---@param x number the x position of the cell
---@param y number the y position of the cell
---@return number Number the cofactor of the matrix
---@section cofactor
function cofactor(self, x, y)
    return determinant(minorOf(self, x, y)) * (x + y) % 2 == 0 and 1 or -1
end
---@endsection

---@class Matrix
---@field inverse function calculate the inverse of the matrix
---@param self Matrix the matrix object
---@return Matrix Matrix the inverse of the matrix
---@section inverse
function inverse(self)
    det = determinant(self)
    if det == 0 then
        return self
    end
    adj = flood(RectMatrix(self.width, self.height), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            adj.data[i][j] = cofactor(self, i, j)
        end
    end
    return scaleMatrix(transpose(adj), 1 / det)
end
---@endsection

---@class Matrix
---@field negate function negate the values of the matrix
---@param self Matrix the matrix object
---@return Matrix Matrix the negated matrix
---@section negate
function negate(self)
    result = flood(RectMatrix(self.width, self.height), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            result.data[i][j] = -self.data[i][j]
        end
    end
    return result
end
---@endsection

---@class Matrix
---@field submatrixAt function get the submatrix at a position
---@param self Matrix the matrix object
---@param row number the row position of the submatrix
---@param col number the column position of the submatrix
---@return Matrix Matrix the submatrix at the position
---@section submatrixAt
function submatrixAt(self, row, col)
    sub = flood(RectMatrix(self.width - 1, self.height - 1), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            if i ~= row and j ~= col then
                sub.data[i > row and i - 1 or i][j > col and j - 1 or j] = self.data[i][j]
            end
        end
    end
    return sub
end
---@endsection

---@class Matrix
---@field maxOfMatrix function get the maximum value of the matrix
---@param self Matrix the matrix object
---@return number Number the maximum value of the matrix
---@section maxOfMatrix
function maxOfMatrix(self)
    max = self.data[1][1]
    for i = 1, self.width do
        for j = 1, self.height do
            max = math.max(max, self.data[i][j])
        end
    end
    return max
end
---@endsection

---@class Matrix
---@field minOfMatrix function get the minimum value of the matrix
---@param self Matrix the matrix object
---@return number Number the minimum value of the matrix
---@section minOfMatrix
function minOfMatrix(self)
    min = self.data[1][1]
    for i = 1, self.width do
        for j = 1, self.height do
            min = math.min(min, self.data[i][j])
        end
    end
    return min
end
---@endsection

---@class Matrix
---@field executeIterate function execute a function on every cell of the matrix and return the modified matrix
---@param self Matrix the matrix object
---@param func function the function to execute on every cell
---@return Matrix Matrix the modified matrix
---@section executeIterate
function executeIterate(self, func)
    for i = 1, self.width do
        for j = 1, self.height do
            self.data[i][j] = func(self.data[i][j])
        end
    end
    return self
end
---@endsection

---@class Matrix
---@field executeEvaluate function execute a function on every cell of the matrix that satisfies a condition and return the modified matrix
---@param self Matrix the matrix object
---@param cond function the condition to evaluate
---@param func function the function to execute on the cell
---@return Matrix Matrix the modified matrix
---@section executeEvaluate
function executeEvaluate(self, cond, func)
    for i = 1, self.width do
        for j = 1, self.height do
            if cond(self.data[i][j]) then
                self.data[i][j] = func(self.data[i][j])
            end
        end
    end
    return self
end
---@endsection

---@class Matrix
---@field modifyResize function modify the size of the matrix
---@param self Matrix the matrix object
---@param rows number the number of rows of the new matrix
---@param cols number the number of columns of the new matrix
---@return Matrix Matrix the modified matrix
---@section modifyResize
function modifyResize(self, rows, cols)
    newMatrix = flood(RectMatrix(rows, cols), 0)
    for i = 1, math.min(self.width, rows) do
        for j = 1, math.min(self.height, cols) do
            newMatrix.data[i][j] = self.data[i][j]
        end
    end
    return newMatrix
end
---@endsection

---@class Matrix
---@field executeWithIterator function execute a function on every cell of the matrix with the iterator
---@param self Matrix the matrix object
---@param func function the function to execute on the cell
---@section executeWithIterator
function executeWithIterator(self, func)
    for i = 1, self.width do
        for j = 1, self.height do
            func(self.data[i][j], i, j)
        end
    end
end
---@endsection

---@class Matrix
---@field toString function convert the matrix to a string
---@param self Matrix the matrix object
---@return string String the string representation of the matrix
---@section toString
function toString(self)
    str = ""
    executeWithIterator(self, function (value, i, j) str = str .. value .. (j == self.height and "\n" or " ") end) --Damn, thats a great way to print a matrix!
    return str
end
---@endsection

---@class Matrix
---@field copy function copy the matrix
---@param self Matrix the matrix object
---@return Matrix Matrix the copied matrix
---@section copy
function copy(self)
    newMatrix = flood(RectMatrix(self.width, self.height), 0)
    for i = 1, self.width do
        for j = 1, self.height do
            newMatrix.data[i][j] = self.data[i][j]
        end
    end
    return newMatrix
end
---@endsection

---@class Matrix
---@field isSquare function check if the matrix is square
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is square
---@section isSquare
function isSquare(self)
    return self.width == self.height
end
---@endsection

---@class Matrix
---@field isSymmetric function check if the matrix is symmetric
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is symmetric
---@section isSymmetric
function isSymmetric(self)
    return isSquare(self) and self == transpose(self)
end
---@endsection

---@class Matrix
---@field isDiagonal function check if the matrix is diagonal
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is diagonal
---@section isDiagonal
function isDiagonal(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if i ~= j and self.data[i][j] ~= 0 then
                return false
            end
        end
    end
    return true
end
---@endsection

---@class Matrix
---@field isIdentity function check if the matrix is an identity matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is an identity matrix
---@section isIdentity
function isIdentity(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if i == j and self.data[i][j] ~= 1 then
                return false
            elseif i ~= j and self.data[i][j] ~= 0 then
                return false
            end
        end
    end
    return true
end
---@endsection

---@class Matrix
---@field isUpperTriangular function check if the matrix is an upper triangular matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is an upper triangular matrix
---@section isUpperTriangular
function isUpperTriangular(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if i > j and self.data[i][j] ~= 0 then
                return false
            end
        end
    end
    return true
end
---@endsection

---@class Matrix
---@field isLowerTriangular function check if the matrix is a lower triangular matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is a lower triangular matrix
---@section isLowerTriangular
function isLowerTriangular(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if i < j and self.data[i][j] ~= 0 then
                return false
            end
        end
    end
    return true
end
---@endsection

---@class Matrix
---@field isOrthogonal function check if the matrix is an orthogonal matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is an orthogonal matrix
---@section isOrthogonal
function isOrthogonal(self)
    return isSquare(self) and self * transpose(self) == RectMatrix(self.width, self.height)
end
---@endsection

---@class Matrix
---@field isNilpotent function check if the matrix is a nilpotent matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is a nilpotent matrix
---@section isNilpotent
function isNilpotent(self)
    return self ^ self.width == RectMatrix(self.width, self.height)
end
---@endsection

---@class Matrix
---@field isSingular function check if the matrix is a singular matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is a singular matrix
---@section isSingular
function isSingular(self)
    return determinant(self) == 0
end
---@endsection

---@class Matrix
---@field isSkewSymmetric function check if the matrix is a skew symmetric matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is a skew symmetric matrix
---@section isSkewSymmetric
function isSkewSymmetric(self)
    return isSquare(self) and self == negate(transpose(self))
end
---@endsection

---@class Matrix
---@field containsNil function check if the matrix contains a nil value
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix contains a nil value
---@section containsNil
function containsNil(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if self.data[i][j] == nil then
                return true
            end
        end
    end
    return false
end
---@endsection

---@class Matrix
---@field purgeNils function remove nil values from the matrix
---@param self Matrix the matrix object
---@return Matrix Matrix the modified matrix
---@section purgeNils
function purgeNils(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if self.data[i][j] == nil then
                self.data[i][j] = 0
            end
        end
    end
    return self
end
---@endsection

---@class Matrix
---@field isZero function check if the matrix is a zero matrix
---@param self Matrix the matrix object
---@return boolean boolean True if the matrix is a zero matrix
---@section isZero
function isZero(self)
    for i = 1, self.width do
        for j = 1, self.height do
            if self.data[i][j] ~= 0 then
                return false
            end
        end
    end
    return true
end
---@endsection