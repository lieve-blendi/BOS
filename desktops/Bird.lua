local Bird = {}
Bird.RGPU = Drivers.rgpu

function Bird:load()
  self.RGPU:clear()
  local w, h = self.RGPU.gpu.getResolution()
  self.RGPU:drawWithInstructions({
    {
      type = "rect",
      x = 3,
      y = 3,
      w = w-3,
      h = w-3,
      pixel = self.RGPU:pixel(0x1c76ba, " ", false),
    },
    {
      type = "text",
      x = 1,
      y = 1,
      text = "Loading Bird Desktop Environment...",
    }
  })
end

function Bird:processSignal(signal)
  if type(signal[1]) == "string" then
    local sw,sy = self.RGPU.gpu.getResolution()
    local event = signal[1]

    if event == "touch" then
      local x, y = signal[2], signal[3]
      if y == sy then
        if x > 2 and x < 11 then
          computer.shutdown(false)
        elseif x > 13 and x < 21 then
          computer.shutdown(true)
        end
      end
    end
  end
end

function Bird:show()
  local sw,sy = self.RGPU.gpu.getResolution()
  self.RGPU.gpu.setBackground(0x064024)
  self.RGPU:clear()

  local debugText = "Memory Usage: " .. tostring(math.floor((computer.totalMemory() - computer.freeMemory()) / computer.totalMemory()*1000 + 0.5)/10) .. "%"

  self.RGPU:drawWithInstructions(
    {
      {type = "rect", x = 1, y = 1, w = sw, h = 1, pixel = self.RGPU:pixel(0x1c76ba, " ", false)},
      {type = "text", x = 2, y = 1, text = OS.name .. " v" .. OS.version .. " - Bird Desktop Environment"},
      {type = "text", x = sw - #debugText, y = 1, text = debugText},
      {type = "rect", x = 1, y = sy, w = sw, h = 1, pixel = self.RGPU:pixel(0x1c76ba, " ", false)}
      {
        type = "text",
        x = 1,
        y = sy,
        text = "| Shutdown | Restart |",
      },
    }
  )
end

return Bird