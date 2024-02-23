<h1>Documentation Chroma-Systems Lua Projects</h1>



<h2>Interactive Map 5x3</h2>


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



<h2>Transponder Locator</h2>


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


