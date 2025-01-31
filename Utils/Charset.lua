letters_at = 10
specials_at = 37
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

--#region loadCharset()

---Load charset from properties and convert to binary strings
---@param numChars number the number of characters in the charset to load
---@return table<binary> table of binary strings representing characters
---@section loadCharset
function loadCharset(numChars)
    charset = {}
    for i = 0, numChars do
        ld = property.getText("cXR" .. i) --0x2b6a
        hex = ld:match("0x(%x+)") --2b6a

        decimal = tonumber(hex, 16) --11146

        binstr = "" ---@type string
        for j = 15, 0, -1 do
            binstr = binstr .. ((decimal >> j) & 1) --0010101101101010
        end

        charset[i] = binstr:reverse()
    end
    return charset
end
---@endsection
--#endregion

--#region drawChar()

---Draw a character of the charset to the screen at the specified position
---@class Charset
---@field drawChar function function to draw a character of the charset to the screen at the specified position
---@param self Charset the charset to draw from
---@param x number the x position to draw the character
---@param y number the y position to draw the character
---@param char number the character to draw
---@section drawChar
function drawChar(self, x, y, char)
    for i = 1, 5 do --5 rows
        for j = 1, 3 do --each row has 3 columns
            a = 16 - ((i - 1) * 3 + j)
            if string.sub(self.chars[char], a, a) == "1" then
                screen.drawRectF(x + j - 1, y + i - 1, 1, 1)
            end
        end
    end
end
---@endsection

--#endregion

---Draw a string to the screen at the specified position
---@param self Charset the charset to draw from
---@param str string the string to draw
---@param x number the x position to draw the string
---@param y number the y position to draw the string
---@section drawString
function drawString(self, str, x, y)
    drawn_chars = 0
    special_code = ""
    record_special = false
    for i = 1, #str do
        xDrawPos = x + drawn_chars * 4
        char = string.sub(str, i, i)
        isAlphabetical, alph_num = charAlphabetical(char)
        isNumerical, num_num = charNumerical(char)

        if isAlphabetical and not record_special then
            drawChar(self, xDrawPos, y, letters_at + alph_num)
            drawn_chars = drawn_chars + 1
        end

        if isNumerical and not record_special then
            drawChar(self, xDrawPos, y, num_num)
            drawn_chars = drawn_chars + 1
        end

        if record_special then
            special_code = isNumerical and special_code .. char or special_code
            if not isNumerical then
                record_special = false
                drawChar(self, xDrawPos, y, specials_at + tonumber(special_code))
                drawn_chars = drawn_chars + 1
                special_code = ""
            end
        end

        if char == "$" then --Order dependent, must be after record_special check because otherwise the $ will be added to the special_code which should only contain numbers
            record_special = true
        end

        if char == " " then
            drawn_chars = drawn_chars + 0.5
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
    return (num < 26 and num > -1), num
end
---@endsection

---Check if a character is numerical and return its value
---@param char string the character to check
---@return boolean isNumerical true if the character is numerical
---@section charNumerical
function charNumerical(char)
    return tonumber(char) ~= nil, tonumber(char)
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