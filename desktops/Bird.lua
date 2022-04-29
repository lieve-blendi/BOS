local Bird = {}
Bird.RGPU = Drivers.rgpu

function Bird:load()
  self.RGPU:clear()
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
  self.RGPU:clear()
  self.RGPU:drawWithInstructions(
    {
      {type = "rect", x = 1, y = 1, w = sw, h = 1, pixel = self.RGPU:pixel(0x1c76ba, " ", false)},
      {type = "text", x = 1, y = 1, text = "BOS"}
    }
  )
end

return Bird