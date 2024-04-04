function drawEllipse(x, y, width, height)
    local centerX = x + width / 2
    local centerY = y + height / 2
    local radiusX = width / 2
    local radiusY = height / 2

    -- Calculate the number of points to draw
    local numPoints = 16
    local angleIncrement = (2 * math.pi) / numPoints

    -- Draw the ellipse
    for i = 1, numPoints do
        local theta = (i - 1) * angleIncrement
        local nextTheta = i * angleIncrement

        local x1 = centerX + radiusX * math.cos(theta)
        local y1 = centerY + radiusY * math.sin(theta)
        local x2 = centerX + radiusX * math.cos(nextTheta)
        local y2 = centerY + radiusY * math.sin(nextTheta)

        screen.drawLine(x1, y1, x2, y2)
    end
end

function drawSphere(x, y, radius, useColor, pickColor, disableRed)
    screen.setColor(pickColor.r, pickColor.g, pickColor.b)
    if useColor then screen.setColor(230, 88, 27) end
    if not disableRed then drawEllipse(x - radius , y - radius, radius * 2, radius * 2) end
    if useColor then screen.setColor(18, 232, 98) end
    radius2 = 1/3 * radius
    drawEllipse(x - radius2 / 2, y - radius, radius2, radius * 2)
    if useColor then screen.setColor(18, 187, 232) end
    drawEllipse(x - radius, y - radius2 / 2, radius * 2, radius2)
end


function projectPoint(point, cameraPosition, cameraRotation, screenWidth, screenHeight, fieldOfView)
    -- Convert camera rotation to transformation matrix
    local rotationMatrix = calculateRotationMatrix(cameraRotation)
    
    -- Translate point relative to camera position
    local translatedPoint = {
        point[1] - cameraPosition[1],
        point[2] - cameraPosition[2],
        point[3] - cameraPosition[3]
    }
    
    -- Apply rotation to translated point
    local rotatedPoint = matrixMultiply(rotationMatrix, translatedPoint)
    
    -- Calculate perspective projection
    local screenX = (rotatedPoint[1] / rotatedPoint[3]) * (fieldOfView / 2) + (screenWidth / 2)
    local screenY = (rotatedPoint[2] / rotatedPoint[3]) * (fieldOfView / 2) + (screenHeight / 2)
    
    return {screenX, screenY}
end


function matrixMultiply(matrix, vector)
    -- Matrix-vector multiplication
    local result = {0, 0, 0}
    for i = 1, 3 do
        for j = 1, 3 do
            result[i] = result[i] + matrix[i][j] * vector[j]
        end
    end
    return result
end

function calculateRotationToOrigin(cameraPosition)
    -- Calculate vector from camera position to origin
    local directionToOrigin = {
        -cameraPosition[1],
        -cameraPosition[2],
        -cameraPosition[3]
    }

    -- Calculate rotation angles
    local yaw = math.atan(directionToOrigin[1], directionToOrigin[3])
    local pitch = math.atan(directionToOrigin[2], math.sqrt(directionToOrigin[1]^2 + directionToOrigin[3]^2))

    return {yaw, pitch, 0}
end

function calculateRotationMatrix(rotation)
    -- Calculate rotation matrix
    local rx = rotation[1]
    local ry = rotation[2]
    local rz = rotation[3]
    
    local cosX = math.cos(rx)
    local sinX = math.sin(rx)
    local cosY = math.cos(ry)
    local sinY = math.sin(ry)
    local cosZ = math.cos(rz)
    local sinZ = math.sin(rz)
    
    local rotationMatrix = {
        {cosY * cosZ,                           cosY * sinZ,                           -sinY},
        {sinX * sinY * cosZ - cosX * sinZ,   sinX * sinY * sinZ + cosX * cosZ,   sinX * cosY},
        {cosX * sinY * cosZ + sinX * sinZ,   cosX * sinY * sinZ - sinX * cosZ,   cosX * cosY}
    }
    
    return rotationMatrix
end