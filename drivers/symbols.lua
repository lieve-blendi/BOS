local Symbols = {}

Symbols["1"] = "!"
Symbols["2"] = "@"
Symbols["3"] = "#"
Symbols["4"] = "$"
Symbols["5"] = "%"
Symbols["6"] = "^"
Symbols["7"] = "&"
Symbols["8"] = "*"
Symbols["9"] = "("
Symbols["0"] = ")"
Symbols["-"] = "_"
Symbols["="] = "+"
Symbols["["] = "{"
Symbols["]"] = "}"
Symbols["\\"] = "|"
Symbols[";"] = ":"
Symbols["'"] = "\""
Symbols[","] = "<"
Symbols["."] = ">"
Symbols["/"] = "?"
Symbols["`"] = "~"

setmetatable(Symbols,
{
  __index = function(tbl, k)
    if type(k) ~= "number" then return end
    for name,value in pairs(tbl) do
      if value == k then
        return name
      end
    end
  end
})

return Symbols