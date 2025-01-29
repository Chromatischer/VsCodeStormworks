letters_at = 10
specials_at = 36
clickableStrings = {}

---Charset class
---@class Charset
---@field chars table table of binary strings representing characters
---@field numChars number number of characters in the charset
---@param numChars number the number of characters in the charset to load
---@return Charset Charset new instance of Charset
---@section Charset
function Charset(numChars)
    return {
        chars = loadCharset(numChars), ---@type table<binary> table of binary strings representing characters
        numChars = numChars, ---@type number number of characters in the charset
    }
end
---@endsection

---Load charset from properties and convert to binary strings
---@param numChars number the number of characters in the charset to load
---@return table<binary> table of binary strings representing characters
---@section loadCharset
function loadCharset(numChars)
    charset = {}
    for i = 1, numChars, 1 do
        ld = property.getText("cXR" .. i) --hexadecimals
        --convert to binary
        bin = ""
        for j = 1, string.len(ld), 1 do
            bin = bin .. string.format("%04d", tonumber(string.sub(string.format("%x", tonumber(string.sub(ld, j, j), 16)), 1, 4)))
        end
        charset[i] = bin
    end
    return charset
end
---@endsection

---Draw a character of the charset to the screen at the specified position
---@class Charset
---@field drawChar function function to draw a character of the charset to the screen at the specified position
---@param self Charset the charset to draw from
---@param x number the x position to draw the character
---@param y number the y position to draw the character
---@param char number the character to draw
---@section drawChar
function drawChar(self, x, y, char)
    --charwidth 3
    --charheight 5

    for i = 1, 5 do
        for j = 1, 3 do
            if string.sub(self.chars[char], (i - 1) * 3 + j, (i - 1) * 3 + j) == "1" then
                screen.drawRectF(x + j - 1, y + i - 1, 1, 1)
            end
        end
    end
end
---@endsection

---Draw a string to the screen at the specified position
---@param self Charset the charset to draw from
---@param str string the string to draw
---@param x number the x position to draw the string
---@param y number the y position to draw the string
---@section drawString
function drawString(self, str, x, y)
    special_code = ""
    record_special = false
    for i = 1, #str do
        xDrawPos = x + (i - 1) * 4
        char = string.sub(str, i, i)
        isAlphabetical, alph_num = charAlphabetical(char)
        isNumerical, num_num = charNumerical(char)

        if isAlphabetical then
            drawChar(self, xDrawPos, y, letters_at + alph_num)
        end

        if isNumerical then
            drawChar(self, xDrawPos, y, num_num)
        end

        if char == "$" then
            record_special = true
        end

        if record_special then
            special_code = special_code .. char
            if char == " " then
                record_special = false
                drawChar(self, xDrawPos, y, specials_at + tonumber(special_code))
                special_code = ""
            end
        end
    end
end
---@endsection

---Check if a character is alphabetical and return its index in the alphabet
---@param char string the character to check
---@return boolean isAlphabetical true if the character is alphabetical
---@return integer num the index of the character in the alphabet
---@section charAlphabetical
function charAlphabetical(char)
    num = string.byte(char) - 65
    return num < 26 and num > -1, num
end
---@endsection

---Check if a character is numerical and return its value
---@param char string the character to check
---@return boolean isNumerical true if the character is numerical
---@section charNumerical
function charNumerical(char)
    return tonumber(char) ~= "fail", tonumber(char)
end
---@endsection

---Draw a clickable string to the screen at the specified position and add it to the event queue to check for clicks
---@param self Charset the charset to draw from
---@param x number the x position to draw the string
---@param y number the y position to draw the string
---@param str string the string to draw
---@param func function the function to run when the string is clicked
---@section clickableString
function clickableString(self, x, y, str, func)
    table.insert(clickableStrings, {x = x, y = y, func = func})
    drawString(self, str, x, y)
end
---@endsection

---Check if a clickableString object has been clicked and run its function
---@param x number x position of the click
---@param y number y position of the click
---@section checkClick
function checkClick(x, y)
    for i = 1, #clickableStrings do
        if isPointInRectangle(x, y, clickableStrings[i].x, clickableStrings[i].y, #clickableStrings[i].str * 4, 5) then
            clickableStrings[i].func()
        end
        clickableStrings[i] = nil --remove the clickable string after checking
    end
end
---@endsection