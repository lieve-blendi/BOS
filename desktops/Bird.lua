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
      text = "Loading Desktop Environment...",
    }
  })
end

function Bird:processSignal(signal)
  if type(signal[1]) == "string" then
    self.RGPU:drawWithInstructions({
      {
        type = "text",
        x = 1,
        y = 2,
        text = signal[1],
      }
    })
  end
end

function Bird:show()
  local sw,sy = self.RGPU.gpu.getResolution()
  self.RGPU.gpu.setBackground(0x000000)
  self.RGPU:clear()

  local debugText = "Memory Usage: " .. tostring((computer.totalMemory() - computer.freeMemory()) / computer.freeMemory) .. "%"

  self.RGPU:drawWithInstructions(
    {
      {type = "rect", x = 1, y = 1, w = sw, h = 1, pixel = self.RGPU:pixel(0x1c76ba, " ", false)},
      {type = "text", x = 1, y = 1, text = "BOS - Bird Desktop Environment"},
      {type = "text", x = sw - #debugText, y = 1, text = debugText}
    }
  )
end

return Bird