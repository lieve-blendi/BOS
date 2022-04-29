local prints = {}

function prints.new(width, height)
  -- Create new print stack

  return {
    width = width,
    height = height,
    stack = {},
    newline = function(self)
      self.stack[(#(self.stack))+1] = ""
    end,
    write = function(self, str)
      if type(str) ~= "string" then str = tostring(str) end

      if #str == 1 then
        if str == "\n" then
          self:newline()
        else
          if #(self.stack[#self.stack]) == self.width then
            self:newline()
            self:write(str)
          else
            self.stack[#(self.stack)] = self.stack[#(self.stack)] .. str
          end
        end
      else
        for i=1,#str do
          self:write(string.sub(str, i, i))
        end
      end
    end,
    show = function(self)
      local o = math.max(#(self.stack) - self.height, 0)

      for y, line in ipairs(self.stack) do
        Components.gpu.set(y - o, line)
      end
    end
  }
end

return prints