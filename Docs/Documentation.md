# Documentation Chroma-Systems Lua Projects

Table of contents:
- [Documentation Chroma-Systems Lua Projects](#documentation-chroma-systems-lua-projects)
  - [Interactive Map 5x3](#interactive-map-5x3)
  - [Transponder Locator](#transponder-locator)
  - [Multifunction Display](#multifunction-display)
  - [Laser Depth Scanner](#laser-depth-scanner)
  - [Car System with 1x(2x1) 2x(1x1) Monitor](#car-system-with-1x2x1-2x1x1-monitor)
    - [1x1 RPS Screen](#1x1-rps-screen)
    - [1x1 Speed Screen](#1x1-speed-screen)
    - [2x1 Multi information main display](#2x1-multi-information-main-display)
  - [Utils](#utils)
  - [Artificial Horizon 2x3](#artificial-horizon-2x3)
  - [How to: Finding a Transponder signal](#how-to-finding-a-transponder-signal)
  - [Multi-screen Controller](#multi-screen-controller)
  - [New TWS System and algorithm](#new-tws-system-and-algorithm)



## Interactive Map 5x3


This is map made specifically for 5x3 monitors. With the current ``Utils.Utils`` it is too large to be able to be pasted into sw directly so you have to strip it down to the necessary functions. It has support for dragging the map. Setting and outputting coordinates. And a radar that also displays target elevation.

For the radar I am using this code:
```lua
function radarToGlobalCoordinates(contactDistance,contactYaw,contactPitch,gpsX,gpsY,gpsZ,compas,pitch)
    globalAngle = math.rad((contactYaw*360 % 360) + compas*-360)
    x = contactDistance * math.sin(globalAngle)
    y = contactDistance * math.cos(globalAngle)
    globalPitch = math.rad((contactPitch*360) + pitch*360)
    z = contactDistance * math.tan(globalPitch)

    return {x=x+gpsX,y=y+gpsY,z=z+gpsZ,age=100}
end
```
which I got from this: [YouTube-Video](https://www.youtube.com/watch?v=1xHabDRpLss&list=PLskhPQFJoZoWC98rLINmkJ5w7MPANnk0a&index=22&t=789s) at minute 13:09 where you can see the whole screenshot of the code. Furthermore the explanation is given in the video itself!



## Transponder Locator


This project should be available for all monitor sizes 2x2 and larger. It has a map display and shows the approximated location of the nearest transponder.

For this to work, you have to drive 100m at a time to collect new data points (this value is subject to change). Every time you have moved 100m a new ``transponderPulsePosition`` will be collected and saved. From two of these positions two circle intersection points are being calculated using this code:
```lua
    d = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    if d > r1 + r2 then
        return {x1 = nil, y1 = nil, x2 = nil, y2 = nil}
    end
    l = (r1^2 - r2^2 + d^2) / (2 * d) --remember? this was your problem :D not putting these parenthesis on the 2*d
    h = math.sqrt(r1^2 - l^2)
    xr1 = (l / d) * (x2 - x1) + (h / d) * (y2 - y1) + x1
    yr1 = (l / d) * (y2 - y1) + (h / d) * (x2 - x1) + y1
    xr2 = (l / d) * (x2 - x1) - (h / d) * (y2 - y1) + x1
    yr2 = (l / d) * (y2 - y1) - (h / d) * (x2 - x1) + y1
    return {x1 = xr1, y1=yr1, x2 = xr2, y2 = yr2}
```
I have struggled with this for two days straight and it is in fact **not** a triangle problem but two circles that have two intersections with each other! The math version of this is:

$$ (1)
 d = \sqrt{(x1-x2)^2 + (y1-y2)^2}
$$
$$ (2)
 l = r1^2 - r2^2 + d^2\div{2d}
$$
$$(3)
 h = \sqrt{r1^2-l^2}
$$
$$
 x = l\div{d} * (x2 - x1) \plusmn h \div{d} (y2 - y1) + x1
$$
$$
 y = l\div{d} * (y2 - y1) \plusmn h \div{d} (x2 - x1) + x1
$$
Because: I have no clue but this is where this link comes from: [math stackexchange](https://math.stackexchange.com/questions/256100/how-can-i-find-the-points-at-which-two-circles-intersect/1033561#1033561)

but this approach still leaves us with two points of intersection which isn't optimal because they could be on opposite ends of each other. Thats why we need another circle intersection so not only do we take the intersection of the current and last position recorded but the one before that too. Which in code looks like this:
```lua
intersectionCurrentLatest = circleIntersection(currentPosition.x,currentPosition.y,currentPosition.range,latestPosition.x,latestPosition.y,latestPosition.range)
intersectionLatestLast = circleIntersection(latestPosition.x,latestPosition.y,latestPosition.range,lastPosition.x,lastPosition.y,lastPosition.range)
```
which gives us four circle intersections in total. But which one is the one that really has the transponder on it? In theory its the one where two circle intersection points lie exactly on top of one another. But because of the limited accuracy of the transponder locator in game I think it is fine to take the point with the least distance to any other point. Which looks like this:
```lua
dist1 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x1,intersectionCurrentLatest.y1,intersectionLatestLast.x1,intersectionLatestLast.y1))
dist2 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x1,intersectionCurrentLatest.y1,intersectionLatestLast.x2,intersectionLatestLast.y2))
dist3 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x2,intersectionCurrentLatest.y2,intersectionLatestLast.x1,intersectionLatestLast.y1))
dist4 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x2,intersectionCurrentLatest.y2,intersectionLatestLast.x2,intersectionLatestLast.y2))

smallest = math.min(dist1,dist2,dist3,dist4)
```
we take the ``math(abs)`` because we don't care about the direction of this deviation. Then we determine the point that in the end had the smallest deviation and enter it into the list of approximations.
```lua
if smallest == dist1 or smallest == dist2 then
    rx = intersectionCurrentLatest.x1
    ry = intersectionCurrentLatest.y1
else
    rx = intersectionCurrentLatest.x2
    ry = intersectionCurrentLatest.y2
end
approximations[#approximations+1] = {x = rx, y = ry, distance = distanceBetweenPoints(rx,ry,gpsX,gpsY)}
```
but thats not all! In theory we can improve accuracy by averaging over the approximations and get a less noisy result in the progress which looks like this:
```lua
averagedApproximation = {x=0,y=0}
for index, approximation in ipairs(approximations) do
    averagedApproximation.x = averagedApproximation.x + approximation.x
    averagedApproximation.y = averagedApproximation.y + approximation.y
end
averagedApproximation.x = averagedApproximation.x / #approximations
averagedApproximation.y = averagedApproximation.y / #approximations
```
but we have to check for the occasional NAN because there could be no intersection of circles at all because of the afore mentioned limited accuracy of the transponder locator. I am using this code for that provided by CodeGPT:
```lua
function isNan(number)
    return number ~= number
end
```
It works because a property of lua NAN is that it is not equal to anything at all including itself and because ~= is the inequality operator this code returns wether or not the number is a NAN type or not (because usually numbers are equal to themselves)! Integrated into the averaging it looks like this:
```lua
averagedApproximation = {x=0,y=0}
for index, approximation in ipairs(approximations) do
    if not isNan(approximation.x) and not isNan(approximation.y) then --check for NAN type and maybe prevent blue screen
        averagedApproximation.x = averagedApproximation.x + approximation.x
        averagedApproximation.y = averagedApproximation.y + approximation.y
    end
end
averagedApproximation.x = averagedApproximation.x / #approximations
averagedApproximation.y = averagedApproximation.y / #approximations
```
where no NANs will be added to the average anymore!
```lua
if (currentApproxPosition or averagedApproximation) and showTransponderLocation then
    if averagedApproximation.number > useAveragedApproximationNumber then --if there is an averaged approximation then use it ofc
        approxOnMapX,approxOnMapY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,averagedApproximation.x,averagedApproximation.y)
    else
        approxOnMapX,approxOnMapY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,currentApproxPosition.x,currentApproxPosition.y)
    end
```
it makes sense to also use the averaged approximations now which is implemented in the code above. Furthermore using averages is only useful if you have enough data averaged out that you get a result with the wanted quality. This is done by checking if the number of averages that went into the average approximation is greater then some constant defined before.

One of the errors I encountered while playtesting was that the code would want to display the newest approximated position, even if it were NANs. this is avoided by iterating backwards from the last to the first index in the array and taking the latest possible approximate position that does not contain NANs which I did here:
```lua
for i=#approximations,1,-1 do
    approximation = approximations[i]
    if not isNan(approximation.x) and not isNan(approximation.y) then
        currentApproxPosition = approximation
        break
    else
        if i == 1 then
            currentApproxPosition = {x = 0, y = 0}
            transponderScore = -999
        end
        transponderScore = transponderScore - 10
    end
end
```
Also deducting points from the new ``transponderScore`` which should in theory show how accurate the system operates at the moment. For every approximation that contains NANs 10 points are deducted from the score. If all of the approximations are NANs (which should not happen) then the current approximation is reset and the score is set to ``-999``.

A usual way to measure accuracy of test results is to calculate the ME or mean error which shows, how far off the average value is from the theoretical correct value. In my case since I want to figure the correct value out the only thing I have is my average approximation which should even out measurement tolerances. By adding up all the errors and then dividing by the number of errors tested for the mean error is calculated. I implemented this here:
```lua
meanError = 0
meanErrorsCollected = 0
if averagedApproximation.number > useAveragedApproximationNumber then -- only calculating mean Error if the number of averages is sufficient
    for index, approximation in ipairs(approximations) do
        if not isNan(approximation.x) and not isNan(approximation.y) then
            --mean error is every error added up and then divided by the number of errors
            meanError = meanError + math.abs(distanceBetweenPoints(approximation.x,approximation.y,averagedApproximation.x,averagedApproximation.y))
            meanErrorsCollected = meanErrorsCollected + 1
        end
    end
    meanError = meanError / meanErrorsCollected
end
```
We again take the ``abs`` because we don't actually care in which direction we are off. Only by how much! This mean error is also used to calculate the approximation score.
```lua
transponderScore = 50 - (meanError / meanErrorEvaluationFactor) --implementing a score for the transponder accuracy at any given time and red
```
this is done right at the start of the evaluation using a Factor to dampen the effect. The score starts out at 50 in the beginning and bigger should mean better.
```lua
transponderScore = transponderScore + (averagedApproximation.number - useAveragedApproximationNumber) * 10 --having a large number of averages should increase the score for every one more than the minimum by ten
```
right after that more points are being added for having more averages used because that should increase accuracy.

Adding the option to not center on the player but the current approximated position.
```lua
if ticks <= 10 or centerOnPlayer then
    mapCenterX = gpsX
    mapCenterY = gpsY
elseif currentApproxPosition then
    oldFactor = 1-mapMovementF
    mapCenterX = mapCenterX * oldFactor + currentApproxPosition.x * mapMovementF
    mapCenterY = mapCenterY * oldFactor + currentApproxPosition.y * mapMovementF
end
```
Because of the jumpy nature of the approximations a ``mapMovementFactor`` is introduced which makes the mapCenter move more smoothly towards the new position from the old position.

To indicate to the user how accurate the approximation is, we have two main ways one is the mean error which is now being displayed as a circle around the current best approximation with corresponding radius.
```lua
--mean error as a circle that shows in what range the transponder could be
meanErrorOnScreenRadius = (meanError / zooms[zoom] / 1000) * Sheight
screen.drawCircle(approxOnMapX, approxOnMapY, meanErrorOnScreenRadius)
```
The other way is through our ``transponderScore`` which is displayed as a string in the bottom right at the moment
```lua
scoreString = string.format("%03d",math.floor(transponderScore))
screen.drawText(Swidth-2-stringPixelLength(scoreString),Sheight-8,scoreString)
```
this should be enough information for the player to use the transponder locator efficiently. With this the project is feature complete!

From playtesting it made sense to only average over the last so many approximations. Code reflects this now:
```lua
averagedApproximation = {x = 0, y = 0, number = 0}
for i=0,19,1 do --only ever using the last 20 approximations in hope of better results
    approximation = approximations[#approximations-i]
    if approximation then
        if not isNan(approximation.x) and not isNan(approximation.y) then --check for NAN type and maybe prevent blue screen
            averagedApproximation.x = averagedApproximation.x + approximation.x
            averagedApproximation.y = averagedApproximation.y + approximation.y
            averagedApproximation.number = averagedApproximation.number + 1
        end
    end
end
```
maybe changing the values around a little bit tomorrow but that is pretty much it!

[[return to Top]](#documentation-chroma-systems-lua-projects)

## Multifunction Display
The Idea of this project is to have a 3x2 monitor that displays multiple parts of important information at once.

- [x] Speed
- [ ] Direction
- [x] Fuel Percentage
- [x] Trip distance
- [x] Fuel usage and milage
- [X] Optional Track display

```lua
screen.setColor(240,115,10)
for index, textField in ipairs(textsToDisplay) do
    screen.drawText(textField.x,textField.y,textField.string)
    textField.format = textField.format and textField.format or 1
    if textField.format == 1 then
        format = "%04d"
    elseif textField.format == 2 then
        format = "%03d"
    elseif textField.format == 3 then
        format = "%0.2f"
    else
        format = "%03d"
    end
    appendix = ""
    if textField.format == 2 then
        appendix = "%"
    elseif textField.format == 4 then
        appendix = "M"
    end
    screen.drawText(textField.x,textField.y + 7,string.format(format,math.floor(textField.variable)) .. appendix)
end
```
this is a library that should improve text rendering dramatically and make changes easier. It takes buttons in a format like this: 
```lua
{x = 2, y = 2, string = "Fuel", variable = anotherVariable, format = 2}
```
where there is a ``x`` and ``y`` position specified at which drawing will begin. Then there is a ``string`` that shows, what you are looking at, a ``variable`` that holds the information and a ``format`` which formats this variable according to a format tag where

| Format | Output |
| ------ | ------ |
|    1   |  0000  |
|    2   |  000%  |
|    3   |  0.00  |
|    4   |  000M  |

This should make development easier for the future.

Moving the table to the ``onTick`` function because the variables have to be updated
```lua
textsToDisplay = {{x = 2, y = 2, string = "FUEL", variable = fuelPercentage, format = 2}}
```

This Idea was scrapped because of the nature of the strings I wanted to display it made little sense to use this method. Instead it looks like this now:
```lua
screen.setColor(240, 115, 10)
screen.drawText(2, 2, "FUEL:" .. string.format("%03d", math.floor(fuelPercentage)) .. "%")
screen.drawText(2, 9, "RNG:" .. string.format("%03d", math.clamp(math.floor(displayRange / 1000), 0, 999)) .. "KM")
uptimeAsHandM = fractionOfHoursToHoursAndMinutes(displayEndurance / 3600)
screen.drawText(2, 16, "TME:" .. string.format("%02d",uptimeAsHandM.h) .. ":" .. string.format("%02d",uptimeAsHandM.m))
screen.drawText(2, 23, "TRK:" .. string.format("%03d", math.clamp(math.floor(trackKilometers), 0, 999)) .. "KM")
```
Where the format is mostly the same but its all done in a similar but not the same way. Wasting that much space for formatting code that in the end wont ever be used that much seemed useless. This now shows the current fuel percentage, the range (kilometers left on tank) the endurance (time left at current usage) and the track Kilometers which need some fixing cause they start at 26 or so.

The Speed dial is looking like this:
```lua
knots = speed * 1.94384
speedFactor = math.clamp(knots / maxSpeed, 0.15, 1)
startRads = math.pi * (1/2) - math.pi * speedFactor
lengthRads = math.pi * 2 * speedFactor
drawCircle(72,23,21,16,startRads,lengthRads)
speedText = "SPEED"
screen.setColor(240,115,10)
screen.drawLine(60,24,83,24)
screen.drawText(72 - stringPixelLength(speedText)/2, 18, speedText)
formatedSpeed = string.format("%03d",math.floor(knots)) .. "KN"
screen.drawText(72 - stringPixelLength(formatedSpeed)/2, 26, formatedSpeed)
```
It's a circle that closes from the top to the bottom with the speed in the middle as digits. First the speed that is in m/s is transformed into knots for easier interpretation by the user. Switching around some values and numbers would make this show KpH or Mph if needed.

Now for the funny track display part. This starts with finding the minimum and maximum ``x`` and ``y`` value from the ```gpsPositions`` array
```lua
minX = math.huge
minY = math.huge
maxX = -math.huge
maxY = -math.huge
for index, trackPoint in ipairs(gpsPositions) do
    minX = math.min(minX, trackPoint.x) --this seams like the best option for that
    minY = math.min(minY, trackPoint.y)
    maxX = math.max(maxX, trackPoint.x)
    maxY = math.max(maxY, trackPoint.y)
end
```
First the variables are set to ``inf`` or ``-inf`` in case of being the maximum. Then we iterate over the entire array and use the ``math.min`` and ``math.max`` functions to get the maximum and minimum values.
```lua
for i = #gpsPositions - 1, 1, -1 do
    currentPosition = gpsPositions[i]
    lastPosition = gpsPositions[i+1]

    currentGpsOnScreenPositionX = onScreenMinX + (percent(currentPosition.x, minX, maxX) * onScreenXWidth) -- then using the previously calculated value to determine the onscreen position
    currentGpsOnScreenPositionY = onScreenMinY + (percent(currentPosition.y, minY, maxY) * onScreenYHeight)

    lastGpsOnScreenPositionX = onScreenMinX + (percent(lastPosition.x, minX, maxX) * onScreenXWidth) -- then using the previously calculated value to determine the onscreen position
    lastGpsOnScreenPositionY = onScreenMinY + (percent(lastPosition.y, minY, maxY) * onScreenYHeight)
    screen.drawLine(lastGpsOnScreenPositionX, lastGpsOnScreenPositionY, currentGpsOnScreenPositionX, currentGpsOnScreenPositionY)
end
```
Then we iterate over the ``gpsPositions`` array from the back to the front because we want to go from last to first. Although it could be done from front to back too I think. The current on screen position is being calculated by first calculating the percentage that the point is from the minimum to the maximum. This function:
```lua
function percent(value, min, max)
    return (value - min) / (max - min) --changed that
end
```
Found in the utils returns a value between 0 and 1. This is then multiplied by the width or height of the window to transform it into screen space. Then all of that is being added to the starting position of the window and a line is drawn.

For calculating the range and endurance this code is being used and updated every 0.5 seconds at the moment:
```lua
distanceTraveled = math.abs(distanceBetweenPoints(gpsX, gpsY, lastGpsX, lastGpsY))
speed = distanceTraveled / updateSeconds --is speed in meters/second
trackKilometers = trackKilometers + (distanceTraveled / 1000) --because the total is being checked

endurance = (fuelLevel / (deltaFuel / updateSeconds)) -- l / l/s should give seconds
range = speed * endurance -- (m/s * s) should give l
```
The math behind it is: $\dfrac{l}{\dfrac{l}{s}}=s$ and for the range you need meters which you can get using the speed and endurance: $\dfrac{m}{s} * s = m$. Speed is just $\dfrac{s}{t}$ which we have in form of the distance traveled and the ``updateSeconds``.
```lua
table.insert(deltaFuelTable, 1, lastFuel - fuelLevel) --adding new values in the beginning of the array
if #deltaFuelTable > maxDFTSize then
    table.remove(deltaFuelTable) --removing the last and oldest value of the array when it gets to large to prevent infinite growth 
end

deltaFuel = 0
deltaFuels = 0
for key, deltaFuelFromTable in pairs(deltaFuelTable) do
    deltaFuels = deltaFuels + 1
    deltaFuel = deltaFuel + deltaFuelFromTable
end
deltaFuel = deltaFuel / deltaFuels
```
The delta fuel so the fuel being used up in the time ``updateSeconds`` is being calculated using this code. Where the current delta fuel (``lastFuel - fuelLevel``) is being inserted at the start of the array ``deltaFuelTable`` so at position 1. Then to get an accurate averaged result the size of the array is limited to ``maxDFTSize``. When the array gets larger then that, the last value is being deleted. Then I just average over the array to get the resulting ``deltaFuel``.

I am using a similar approach for the ``gpsPositions`` table which is used for the Track display.
```lua
if #gpsPositions > 1 then
    lastGpsPos = gpsPositions[1]
    if math.abs(distanceBetweenPoints(lastGpsPos.x, lastGpsPos.y, gpsX, gpsY)) > 10 then
        table.insert(gpsPositions, 1, {x = gpsX, y = gpsY})
    end
    if #gpsPositions > gpsDataPoints then
        table.remove(gpsPositions)
    end
else
    table.insert(gpsPositions, 1, {x = gpsX, y = gpsY})
end
```
Where to stop the array from deleting old tracking data it's first checked if the vehicle has moved more then 10 meters. Then at array position one the new data is inserted and in case of a too long array the last data point is deleted. The first condition is necessary because we need the ``lastGpsPos`` to determine the distance.

[[return to Top]](#documentation-chroma-systems-lua-projects)


## Laser Depth Scanner

Ok so this project has a similar idea to something like [this YouTube](https://www.youtube.com/watch?v=lSwwEqzLPmw) video shows but with a stationary boat or other thing. The Idea is to have a laser scan the whole width and height of the screen and the output it using colors to show the depth at each pixel of the screen. Furthermore you should have to option to
 - [X] Zoom
 - [X] Make the Image faster
 - [X] reset the screen
 - [ ] Vertical Scroll mode 

So with the goals of this project I got to work on programming it, with until now little success. But what I think is working is this code:
```lua
currrentOnScreenLaserX = currrentOnScreenLaserX + pixelScanSize
if currrentOnScreenLaserX > Swidth / pixelScanSize then
    currrentOnScreenLaserX = 0
    currrentOnScreenLaserY = currrentOnScreenLaserY + pixelScanSize
    if currrentOnScreenLaserY > Sheight / pixelScanSize then
        currrentOnScreenLaserY = 0
    end
end

currentLaserX = ((maxLaserFOV * 2) * ((currrentOnScreenLaserX * pixelScanSize) / Swidth)) - 1
currentLaserY = ((maxLaserFOV * 2) * ((currrentOnScreenLaserY * pixelScanSize) / Sheight)) - 1
output.setNumber(1,currentLaserX)
output.setNumber(2,currentLaserY)
```
So what it does from top to bottom is in the first few lines it steps the Laser from 0 to the screens width in steps of ``pixelScanSize`` pixels. Increasing this number will make the scan process faster but also reduce the output quality of the picture. The laser always goes to the end of one Line and then to the next line.
The second part of this code transforms this code into laser positioning data that can be sent directly to the laser. First you have the ``maxLaserFOV`` which determines the zoom factor of the laser. Reducing this should give you a smaller area of the see-floor and with that a zoomed image but no reduction in time. This is then multiplied by two because I think the laser goes from -1 to 1. Thats also why in the end 1 is being subtracted from this value. To transform the pixel coordinates that should be scanned into a range of 0 to 1 first the ``currentOnScreenLaser`` position is multiplied by the ``pixelScanSize`` then this is being divided by the screens dimensions. THIS MAY BE WRONG BUT I DON'T KNOW. 

So it turns out I was in deed wrong! The error was right above this text. Dividing the Screen width and Screen height by ``pixelScanSize`` breaks the whole darn thing!
```lua
if doScan then
    currrentOnScreenLaserX = currrentOnScreenLaserX + pixelScanSize
    if currrentOnScreenLaserX > Swidth then
        currrentOnScreenLaserX = 0
        currrentOnScreenLaserY = currrentOnScreenLaserY + pixelScanSize
        if currrentOnScreenLaserY > Sheight then
            currrentOnScreenLaserY = 0
        end
    end
end
```
This is how it looks now. And it even looks way simpler so no need to make it way to complicated... Furthermore it makes the second part of the code simpler too!
```lua
currentLaserY = ((maxLaserFOV * 2) * (currrentOnScreenLaserY / Sheight)) - 1
currentLaserX = ((maxLaserFOV * 2) * (currrentOnScreenLaserX / Swidth)) - 1
```
This fixes more of the bugs too Yippie!

For the drawing part it now looks like this:
```lua
screen.setColor(0, 0, 0, 255)
screen.drawClear()
for ypos, xarray in pairs(LaserDistances) do
    for xpos, distance in pairs(xarray) do
        colorshift = percent(distance, minDistance, maxDistance) * 1
        screen.setColor(240, 115, 10, (230 * colorshift) + 25)
        screen.drawRectF(xpos, ypos, pixelScanSize, pixelScanSize)
        if xpos == currrentOnScreenLaserX and ypos == currrentOnScreenLaserY then
            screen.setColor(255, 255, 255)
            screen.drawRect(currrentOnScreenLaserX - 1, currrentOnScreenLaserY - 1, pixelScanSize + 1, pixelScanSize + 1)
        end
    end
end
```
The values may need to be adjusted while testing in game. It iterates through the ``LaserDistances`` and inside of that the ``xarray`` which is gives us the data. Then we take a predetermined min and max distance calculate a percentage with that and use it to calculate a shift into the color of the pixel to draw on screen. And then on top of all of that we draw the indicator in white of the current pixel that is being drawn to screen.

Like in the [Multifunction-Display](#multifunction-display) which had the track indicator, we calculate a min and max value from the array of data using:
```lua
minDistance = math.huge
maxDistance = -math.huge
for n, xarray in pairs(LaserDistances) do
    for m, distance in pairs(xarray) do
        minDistance = math.min(minDistance, distance)
        maxDistance = math.max(maxDistance, distance)
    end
end
```
This piece of code. (I might just add that into one of the Utils so that I have it ready as a single function!). It's way too late now and I have been working for 2h again so thats why there are no in-line comments. Good luck future me in trying to debug any of this! Hopefully you are as smart as I am!


[[return to Top]](#documentation-chroma-systems-lua-projects)

## Car System with 1x(2x1) 2x(1x1) Monitor

First 1x1 Monitor should have:

- [X] RPS

in a Dial form with a pointer and the number

Second 1x1 Monitor should have:

- [X] Speed

also in Dial form with a pointer and the number

The 2x1 Monitor should have:

- [X] Gear
- [X] Fuel
- [X] Battery
- [X] Temperature

this should be everything that you need for a Car display!
Lets start! Idea is not to have touch so to not make it too complicated!

### 1x1 RPS Screen
The 1x1 RPM / RPS Screen is finished now and I will use the same structure and base framework for the Speed Monitor!
I have added some additional Utility functions in the ``Circle_Draw_Utils``. First is the ``drawSmallLinesAlongCircle()`` function which expands on the ``drawCircle()`` function and draws indicator lines form the circles radius to the center of the circle. The second is the ``drawIndicatorInCircle()`` function which draws an indicator with a specified length from the middle of the circle and shows the current value within the min and max value.
These functions were taken over from my old notes on steam so I have no clue how they are working!

The code for the RPM Screen is really simple:
```lua
currentRPM = (input.getNumber(1) * 60 * 0.05) + currentRPM * 0.95
minRPM = property.getNumber("Min RPS") * 60
maxRPM = property.getNumber("Max RPS") * 60
rpmIndicator = math.clamp(percent(currentRPM, minRPM, maxRPM),0,1)
```
First all fluctuations are evened out using a WMA then everything is transformed into RPM using * 60.

And I think that the draw Code should be self explanatory because its just a number of function calls to draw the UI.

### 1x1 Speed Screen
Its basically just a 1 to 1 copy of the 1x1 RPS Screen but with speed instead of displaying RPS

### 2x1 Multi information main display
Now also comes with even more information then was previously planned! It has the Range and Endurance script from my multifunction 2x2 project! It is split up into 4 parts. Three of them are just the same thing again and again but with different values.

The fourth one is directly taken from the Multifunction 2x2 project

## Utils 
Utils are split up into many smaller files to not clutter up small projects with unnecessary functions.




[[return to Top]](#documentation-chroma-systems-lua-projects)


## Artificial Horizon 2x3

using:

| Input | Value            |
|-------|------------------|
|   1   | pitch            |
|   2   | roll             |
|   3   | altitude         |
|   4   | speed            |
|   5   | heading          |
|   6   | flight direction |

Features:
- Horizon Line
    - Earth and Sky as different colors
- Horizon Line as white line across
- Standing Aircraft Indicator
    - In white when in flight
    - Wit color and different Arrows and directions when near hovering or standing still (3D indicator)
- Speed and altitude indicator with change on each of the sides

## How to: Finding a Transponder signal

To start, lets begin by defining the problem that we want to solve:
 - We want to find a specific location, relying only on the distance, we received from a couple of beacon points.

Beacons have the following format: `{x, y, d}` where X and Y are the position where the distance d was recorded. My first thought into this was, that of course this is a circle intersection problem, as explained here: [Github Code version of Algorithm](https://gist.github.com/jupdike/bfe5eb23d1c395d8a0a1a4ddd94882ac), this would be the ideal solution.

But it isn't! Because for one, two circles almost always intersect in two points, at which point you need to pick one, and hope that you guessed right. Furthermore, as I found out way too deep into my second attempt at this ([First Attempt](/Transponder_Triangulator_Variable.lua), [Second Attempt](/TransponderLocate.lua)). Both failed, because I din't consider the limitations of Stormworks transponder locators.

For example, I had just finished my second attempt's logic system, when I found out, that when heading towards or away from the transponder, the estimate would be placed to the side of the vessel. This may be attributed to the fact, that the resolution of the Stormworks transponder locator is poor. Therefore instead of all the circles being tangential and meeting at the origin point, they would overlap just slightly and paint a line of reasonable estimates along the right side of the vessel. Why it always preferred the right side, I don't know...

Furthermore, my implementation to find the correct of the two circle intersection points involved cross-checking every single intersection with every other one:
```lua
function findBestIntersectionPoint(intersections)
    bestIntersection = {}
    bestDistance = math.huge
    number = 0
    for i = 1, #intersections do
        sum = 0
        for j = 1, #intersections do
            if i ~= j then
                sum = sum + math.sqrt((intersections[i].x - intersections[j].x) ^ 2 + (intersections[i].y - intersections[j].y) ^ 2)
                number = number + 1
            end
        end
        if sum < bestDistance then
            bestDistance = sum
            bestIntersection = intersections[i]
        end
    end
    return bestIntersection, bestDistance, number
end
```
This lead to a time complexity (just for this step) of $(n^2)-n$ or $O(n^2)$. This was so bad, that I could only use the latest 25 intersection points (600 calculations / tick), before the physics FPS would start to drop. I hope, that this approach fixes that issue!

All the issues aside, the code still looked way better, then some of the other things I have written before xD:
```lua
if math.abs(math.sqrt((lastRecordPosition.x - gpsX) ^ 2 + (lastRecordPosition.y - gpsY) ^ 2)) > 10 then --only record a new pulsePoint if the distance between the last recorded position and the new position is greater than 10 meters to avoid recording the same position multiple times
    table.insert(pulsePoints, {x = pulseX, y = pulseY, r = tDistanceAnalog})
    lastRecordPosition = {x = gpsX, y = gpsY}
    if #pulsePoints > 1 then --only calculate the intersection points if there are at least two pulsePoints
        intersectionPoints = circleIntersection(pulsePoints[#pulsePoints], pulsePoints[#pulsePoints - 1])
        if intersectionPoints then
            table.insert(intersections, {x = intersectionPoints[1], y = intersectionPoints[2]})
            table.insert(intersections, {x = intersectionPoints[3], y = intersectionPoints[4]})
        end
        --only calculate the best intersection point for the latest 50 pulsePoints because of the resource intensity
        if #intersections > 0 then
            table.insert(bestIntersectionArray, intersections[#intersections])
            if # bestIntersectionArray > intersectionNum then
                table.remove(bestIntersectionArray, 1)
            end
            bestIntersection, bestDistance, numCalculations = findBestIntersectionPoint(bestIntersectionArray)
        end
    end
end
```
I must say, that this looks visually pleasing and the use of the `table` function makes this very readable. Only sad that it doesn't work...

But what is the real solution here? As it turns out, it is Trilateration, as it is beautifully explained [in this article](https://www.alanzucconi.com/2017/03/13/positioning-and-trilateration/). It shows, why two circles are not enough and you need a third one to find the origin. I have tried visualizing it [using desmos](https://www.desmos.com/calculator/hbwmir6brc?lang=de).

The article comes to the conclusion, that this is not a math problem, but more an optimization problem. The minimization of the distance between the point and the circumference of an arbitrary amount of circles. In the example, I have used three, but theoretically any number would be possible.

To do this, the article suggest the use of the mean squared error and a gradient descend loop to approximate the origin as closely as necessary. I have implemented this in code as my [Trilateration Utils](/Utils/TrilaterationUtils.lua).

The execution is pretty simple, I will go over it step by step:
 - Take an educated guess, to where the center could be. This is done, by taking the average X and Y coordinate of all the beacons
 - For any given guess, calculate the euclidean distance to each of the beacons and take the mean squared error to the provided distances
 - Use a gradient descend loop to minimize the mean squared error
 - Stop, when the accuracy is big enough

All of this works and is available in the afore mentioned TrilaterationUtils file. This provides all the necessary functions to make this possible!

The rest of the UI / UX design should be trivial xoxo!

The idea for the logic is still pretty straight forward:
 - Take a point every 50 - 100m or so
 - Calculate new position based on the previous point as a starting point
 - Display on screen
 
[[return to Top]](#documentation-chroma-systems-lua-projects)


## Multi-screen Controller
The Idea for this controller existed for a long time and tries to fix the following problem: imagine, you have a lot of instruments and different micro controllers, who's data you want to display all at once, but you only have two 2x3 monitors and a little space in between them.

By adding this controller, I can share information across my different projects, allow the user to pick, which display elements he prefers the most and have ample space on the dash, so that I don't need 6 2x3 monitors to have the option to display the fish-finder and the radar at the same time.

The BUS-Layout is as follows:
 - Number Channels:
    - Global Scale (Individual MCs can divert from that)
    - GPS- / X / Y / Z (so that MC's can use the Multi-Controllers BUS instead of the standard physics sensor)
    - Vehicle Compass
    - Selected Module on Screen I  (For the individual MCs to know, if they are active)
    - Selected Module on Screen II
    - Touch I - / X / Y (So that the MCs can pick, which monitors touch input, they want to accept)
    - Touch II- / X / Y
  - Boolean Channels
    - Global Dark mode
    - Screen I  depressed
    - Screen II depressed

The Global scale is supposed to make it easy, to zoom on all the screens at the same time, so that information can be transferred from one to the other more easily.

The Global Dark mode removes the need, to have every screen have an individual dark mode setting / button and improve the user experience.

[[return to Top]](#documentation-chroma-systems-lua-projects)


## New TWS System and algorithm

The basic idea is the same as before, doing a step by step approach like this:
 - Collect new Radar data
 - Update existing tracks using the new data
 - Add Tracks for all new Data that was not used
 - Delete old tracks that are no longer of interest

The basic Idea behind the Update, is that you need to cross reference every single new Data point with every single track. Then choose the one with the smallest distance, that is larger then a threshold T. This can be accomplished using a two dimensional matrix, where you have rows of new data and columns of tracks and the distance as the value.
Using this method, you can then: iterate backwards through the array and set a flag to the updated tracks, so that they won't be updated again.
