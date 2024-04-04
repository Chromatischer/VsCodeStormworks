require("Utils.Utils")

---lerps between a color A and B and returns the color data for the result
---@param colorA table color table format {r, g ,b}
---@param colorB table color table format {r, g ,b}
---@param factor number the lerping factor mixing the colors
---@return table colorData the color data in the {r, g, b} format
---requires: percent() from Utils.Utils
function colorLerp(colorA, colorB, factor)
    rA = colorA.r
    gA = colorA.g
    bA = colorA.b
    rB = colorB.r
    gB = colorB.g
    bB = colorB.b

    gR = lerp(factor, gA, gB)
    bR = lerp(factor, bA, bB)
    rR = lerp(factor, rA, rB)

    return {r = rR, g = gR, b = bR}
end