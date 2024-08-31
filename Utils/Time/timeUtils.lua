---truns 10.5 hours into 10h and 30m
---@param fraction number the number of hours
---@return table time_information h are the hours and m are minutes
function fractionOfHoursToHoursAndMinutes(fraction)
    hours = math.floor(fraction) -- Get the whole number of hours
    remainingFraction = fraction - hours -- Get the remaining fraction of an hour
    minutes = math.floor(remainingFraction * 60) -- Calculate the number of minutes
    return {h=hours, m=minutes}
end