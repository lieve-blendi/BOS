local Keys = {} -- totally not stolen from OpenOS

Keys["1"]           = 0x02
Keys["2"]           = 0x03
Keys["3"]           = 0x04
Keys["4"]           = 0x05
Keys["5"]           = 0x06
Keys["6"]           = 0x07
Keys["7"]           = 0x08
Keys["8"]           = 0x09
Keys["9"]           = 0x0A
Keys["0"]           = 0x0B
Keys.a               = 0x1E
Keys.b               = 0x30
Keys.c               = 0x2E
Keys.d               = 0x20
Keys.e               = 0x12
Keys.f               = 0x21
Keys.g               = 0x22
Keys.h               = 0x23
Keys.i               = 0x17
Keys.j               = 0x24
Keys.k               = 0x25
Keys.l               = 0x26
Keys.m               = 0x32
Keys.n               = 0x31
Keys.o               = 0x18
Keys.p               = 0x19
Keys.q               = 0x10
Keys.r               = 0x13
Keys.s               = 0x1F
Keys.t               = 0x14
Keys.u               = 0x16
Keys.v               = 0x2F
Keys.w               = 0x11
Keys.x               = 0x2D
Keys.y               = 0x15
Keys.z               = 0x2C

Keys.apostrophe      = 0x28
Keys.at              = 0x91
Keys.back            = 0x0E -- backspace
Keys.backslash       = 0x2B
Keys.capital         = 0x3A -- capslock
Keys.colon           = 0x92
Keys.comma           = 0x33
Keys.enter           = 0x1C
Keys.equals          = 0x0D
Keys.grave           = 0x29 -- accent grave
Keys.lbracket        = 0x1A
Keys.lcontrol        = 0x1D
Keys.lmenu           = 0x38 -- left Alt
Keys.lshift          = 0x2A
Keys.minus           = 0x0C
Keys.numlock         = 0x45
Keys.pause           = 0xC5
Keys.period          = 0x34
Keys.rbracket        = 0x1B
Keys.rcontrol        = 0x9D
Keys.rmenu           = 0xB8 -- right Alt
Keys.rshift          = 0x36
Keys.scroll          = 0x46 -- Scroll Lock
Keys.semicolon       = 0x27
Keys.slash           = 0x35 -- / on main keyboard
Keys.space           = 0x39
Keys.stop            = 0x95
Keys.tab             = 0x0F
Keys.underline       = 0x93

-- Keypad (and numpad with numlock off)
Keys.up              = 0xC8
Keys.down            = 0xD0
Keys.left            = 0xCB
Keys.right           = 0xCD
Keys.home            = 0xC7
Keys["end"]         = 0xCF
Keys.pageUp          = 0xC9
Keys.pageDown        = 0xD1
Keys.insert          = 0xD2
Keys.delete          = 0xD3

-- Function Keys
Keys.f1              = 0x3B
Keys.f2              = 0x3C
Keys.f3              = 0x3D
Keys.f4              = 0x3E
Keys.f5              = 0x3F
Keys.f6              = 0x40
Keys.f7              = 0x41
Keys.f8              = 0x42
Keys.f9              = 0x43
Keys.f10             = 0x44
Keys.f11             = 0x57
Keys.f12             = 0x58
Keys.f13             = 0x64
Keys.f14             = 0x65
Keys.f15             = 0x66
Keys.f16             = 0x67
Keys.f17             = 0x68
Keys.f18             = 0x69
Keys.f19             = 0x71

-- Japanese keyboards
Keys.kana            = 0x70
Keys.kanji           = 0x94
Keys.convert         = 0x79
Keys.noconvert       = 0x7B
Keys.yen             = 0x7D
Keys.circumflex      = 0x90
Keys.ax              = 0x96

-- Numpad
Keys.numpad0         = 0x52
Keys.numpad1         = 0x4F
Keys.numpad2         = 0x50
Keys.numpad3         = 0x51
Keys.numpad4         = 0x4B
Keys.numpad5         = 0x4C
Keys.numpad6         = 0x4D
Keys.numpad7         = 0x47
Keys.numpad8         = 0x48
Keys.numpad9         = 0x49
Keys.numpadmul       = 0x37
Keys.numpaddiv       = 0xB5
Keys.numpadsub       = 0x4A
Keys.numpadadd       = 0x4E
Keys.numpaddecimal   = 0x53
Keys.numpadcomma     = 0xB3
Keys.numpadenter     = 0x9C
Keys.numpadequals    = 0x8D

-- Create inverse mapping for name lookup.
setmetatable(Keys,
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

return Keys