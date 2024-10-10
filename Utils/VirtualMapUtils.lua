function virtualMap(centerX, centerY, screenWidth, screenHeight, maxRadius)
    return {
        centerX = centerX,
        centerY = centerY,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        screenRadius = math.min(screenWidth, screenHeight),
        maxRadius = maxRadius,

        globalToOnScreen = function (self, globalX, globalY, vesselAngle)
            localX = globalX * math.sin(vesselAngle) - self.centerX
            localY = globalY * math.cos(vesselAngle) - self.centerY

            onScreenX = localX / maxRadius * self.screenRadius
            onScreenY = localY / maxRadius * self.screenRadius

            return onScreenX, onScreenY
        end,

        updateCenter = function (self, globalX, globalY)
            self.centerX, self.centerY = globalX, globalY
        end,

        updateMaxRadius = function (self, newMaxRadius)
            self.maxRadius = newMaxRadius
        end

        --TODO: Test all of this, none might work, maybe it will though?
    }
end