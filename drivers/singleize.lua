local Singleize = {}

function Singleize.Singleize(char)
    if char == "grave" then return "`" end
    if char == "minus" then return "-" end
    if char == "equal" then return "=" end
    if char == "lbracket" then return "[" end
    if char == "rbracket" then return "]" end
    if char == "semicolon" then return ";" end
    if char == "apostrophe" then return "'" end
    if char == "backslash" then return "\\" end
    if char == "comma" then return "," end
    if char == "period" then return "." end
    if char == "slash" then return "/" end
    return char
end

return Singleize