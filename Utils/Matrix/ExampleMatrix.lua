require("Utils.Matrix.Matrix")
--write some examples of how to use the matrix class and all its functions

exmOne = flood(Matrix(3), 1)
exmTwo = flood(Matrix(3), 2)

print(toString(exmOne))
print(toString(exmTwo))

added = addMatrix(exmOne, exmTwo)

print(toString(added))

subtracted = subtractMatrix(exmOne, exmTwo)

print(toString(subtracted))

exmThree = flood(Matrix(3), 3)

multiplied = multiplyMatrix(exmOne, exmThree)

print(toString(multiplied))

exmFour = flood(Matrix(3), 4)

print(toString(exmFour))

exmFive = modifyResize(flood(Matrix(3), 5), 4, 4)

print(toString(exmFive))

exmSix = executeEvaluate(exmFive, function (x) return x == 0 end, function (x) return 1 end)

print(toString(exmSix))

exmSeven = executeIterate(exmFive, function (x) return x == 0 and 1 or x end)

print(toString(exmSeven))

exmEight = executeIterate(exmSeven, function (x) return x + 1 end)

print(toString(exmEight))

exmMin = minOfMatrix(exmEight)

exmMax = maxOfMatrix(exmEight)

exmAvg = averageMatrix(exmEight)

print(exmMin .. "<" .. exmAvg .. "<" .. exmMax)

exmNine = scaleMatrix(exmEight, 3)

print(toString(exmNine))

exmTen = inverse(exmNine)

print(toString(exmTen))

exmEleven = negate(exmNine)

print(toString(exmEleven))

exmTwelve = transpose(exmNine)

print(toString(exmTwelve))

exmDet = determinant(exmNine)

print(exmDet)

exmCof = cofactor(exmNine, 2, 2)

print(exmCof)

exmThirteen = submatrixAt(exmNine, 2, 2)

print(toString(exmThirteen))

exmFourteen = minorOf(exmNine, 2, 2)
