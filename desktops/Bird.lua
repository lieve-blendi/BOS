local Bird = {}
Bird.RGPU = Drivers.rgpu

function Bird:processSignal(signal)

end

function Bird:show()
  local sw,sy = Bird.RGPU.gpu.getResolution()
  Bird.RGPU:drawWithInstructions(
    {
      {type = "rect", x = 1, y = 1, w = sw, h = 1, pixel = Bird.RGPU:pixel("0x1c76ba", " ", false)},
      {type = "text", x = 1, y = 1, text = "ur mom"}
    }
  )
end

return Bird