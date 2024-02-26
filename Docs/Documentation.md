# Documentation Chroma-Systems Lua Projects

Table of contents:
- [Documentation Chroma-Systems Lua Projects](#documentation-chroma-systems-lua-projects)
  - [Interactive Map 5x3](#interactive-map-5x3)
  - [Transponder Locator](#transponder-locator)
  - [Multifunction Display](#multifunction-display)
  - [Utils](#utils)



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


## Utils 
Utils are split up into many smaller files to not clutter up small projects with unnecessary functions.




[[return to Top]](#documentation-chroma-systems-lua-projects)



